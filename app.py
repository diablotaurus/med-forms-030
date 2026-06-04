# -*- coding: utf-8 -*-
#
# med-forms-030 — веб-приложение для учётных форм 030/у-Д/с и 030-ПО/у
# Copyright (C) 2026 diablotaurus
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""
Веб-приложение для учётной формы N 030/у-Д/с
"Карта диспансеризации несовершеннолетнего".

Хранит заполненные карты в базе SQLite (base.db), позволяет создавать,
редактировать, удалять и печатать формы.

Запуск:
    pip install flask
    python app.py
затем открыть http://127.0.0.1:5000
"""
import calendar
import json
import os
import re
import sqlite3
from datetime import datetime, timedelta
from functools import wraps

from flask import (Flask, g, redirect, render_template, request, url_for, abort,
                   session)
from werkzeug.security import generate_password_hash, check_password_hash

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "base.db")

# Тайм-аут бездействия: после стольких минут без активности нужен повторный вход
SESSION_TIMEOUT = timedelta(hours=2)

# Учётные данные по умолчанию (создаются при первом запуске, смените после входа)
DEFAULT_USER = "admin"
DEFAULT_PASSWORD = "admin"

# Типы форм: ключ -> описание, краткое имя, шаблон, скрипт
FORM_TYPES = {
    "030": {
        "short": "030/у-Д/с",
        "title": "Карта диспансеризации несовершеннолетнего",
        "template": "form_030.html",
    },
    "030po": {
        "short": "030-ПО/у",
        "title": "Карта профилактического медицинского осмотра несовершеннолетнего",
        "template": "form_030po.html",
    },
}
DEFAULT_FORM_TYPE = "030"

# Версия приложения (единый источник). Меняется при выпуске новой версии.
APP_VERSION = "0.1.4"

app = Flask(__name__)


@app.context_processor
def inject_globals():
    """Делает версию доступной во всех шаблонах как {{ app_version }}."""
    return {"app_version": APP_VERSION}


# Секретный ключ генерируется заново при каждом запуске процесса.
# Поэтому после перезапуска сервера все ранее выданные сессии становятся
# недействительными — требуется повторный вход (так безопаснее).
app.secret_key = os.urandom(32)

# Авто-выход по бездействию: сессия живёт SESSION_TIMEOUT и продлевается
# при каждом запросе (скользящий тайм-аут).
app.permanent_session_lifetime = SESSION_TIMEOUT
app.config["SESSION_REFRESH_EACH_REQUEST"] = True


@app.before_request
def _refresh_session_timeout():
    # делает сессию «постоянной», чтобы к ней применялся срок жизни
    session.permanent = True


# --------------------------------------------------------------------------
#  База данных
# --------------------------------------------------------------------------
def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(exc):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    db = sqlite3.connect(DB_PATH)
    db.execute(
        """
        CREATE TABLE IF NOT EXISTS forms (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_fio TEXT,
            birth_date  TEXT,
            created_at  TEXT,
            updated_at  TEXT,
            data        TEXT
        )
        """
    )
    db.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            username      TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL
        )
        """
    )
    db.execute(
        """
        CREATE TABLE IF NOT EXISTS settings (
            key   TEXT PRIMARY KEY,
            value TEXT
        )
        """
    )
    # миграция: добавить недостающие столбцы
    cols = [r[1] for r in db.execute("PRAGMA table_info(forms)").fetchall()]
    if "form_type" not in cols:
        db.execute("ALTER TABLE forms ADD COLUMN form_type TEXT DEFAULT '030'")
        db.execute("UPDATE forms SET form_type = '030' WHERE form_type IS NULL")
    if "deleted" not in cols:
        db.execute("ALTER TABLE forms ADD COLUMN deleted INTEGER DEFAULT 0")
        db.execute("UPDATE forms SET deleted = 0 WHERE deleted IS NULL")
    # завести пользователя по умолчанию, если пользователей ещё нет
    count = db.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    if count == 0:
        db.execute(
            "INSERT INTO users (username, password_hash) VALUES (?, ?)",
            (DEFAULT_USER, generate_password_hash(DEFAULT_PASSWORD)),
        )
    db.commit()
    db.close()


# --------------------------------------------------------------------------
#  Авторизация
# --------------------------------------------------------------------------
def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("user"):
            return redirect(url_for("login", next=request.path))
        return view(*args, **kwargs)
    return wrapped


# --------------------------------------------------------------------------
#  Вспомогательное
# --------------------------------------------------------------------------
def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def collect_form():
    """Собрать все поля формы в словарь (отмеченные чекбоксы приходят как 'on')."""
    return {k: v for k, v in request.form.items()}


def get_setting(key, default=""):
    row = get_db().execute(
        "SELECT value FROM settings WHERE key = ?", (key,)
    ).fetchone()
    return row["value"] if row and row["value"] is not None else default


def set_setting(key, value):
    db = get_db()
    db.execute(
        "INSERT INTO settings (key, value) VALUES (?, ?) "
        "ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        (key, value),
    )
    db.commit()


# --------------------------------------------------------------------------
#  Серверная проверка данных (дублирует проверку в браузере)
# --------------------------------------------------------------------------
DATE_FIELDS = {
    # форма 030/у-Д/с
    "birth_date": "дата рождения",
    "date_postup": "дата поступления в стационарное учреждение",
    "date_vyb": "дата выбытия",
    "date_disp_start": "дата начала диспансеризации",
    "inv_first_date": "инвалидность установлена впервые",
    "inv_last_date": "дата последнего освидетельствования",
    "ipr_date": "дата назначения ИПР",
    "date_fill": "дата заполнения",
    # форма 030-ПО/у
    "date_osmotr_start": "дата начала профилактического осмотра",
    "inv_first_date_po": "инвалидность установлена впервые",
    "inv_last_date_po": "дата последнего освидетельствования",
}


def is_valid_date(s):
    m = re.match(r"^(\d{2})\.(\d{2})\.(\d{4})$", s)
    if not m:
        return False
    d, mo, y = int(m.group(1)), int(m.group(2)), int(m.group(3))
    if mo < 1 or mo > 12:
        return False
    if y < 1900 or y > 2100:
        return False
    return 1 <= d <= calendar.monthrange(y, mo)[1]


def is_valid_snils(s):
    digits = re.sub(r"\D", "", s)
    if len(digits) != 11:
        return False
    if int(digits[:9]) <= 1001998:  # малые номера выдавались без контрольной суммы
        return True
    total = sum(int(digits[i]) * (9 - i) for i in range(9))
    ctrl = total % 101
    if ctrl == 100:
        ctrl = 0
    return ctrl == int(digits[9:11])


def validate_form(data):
    """Вернуть список сообщений об ошибках (пустой список — данные корректны)."""
    errors = []
    for field, label in DATE_FIELDS.items():
        v = (data.get(field) or "").strip()
        if v and not is_valid_date(v):
            errors.append(f"Некорректная дата «{v}» (нужен формат дд.мм.гггг) — {label}")
    snils = (data.get("snils") or "").strip()
    if snils and not is_valid_snils(snils):
        errors.append(
            f"Некорректный СНИЛС «{snils}» (формат ХХХ-ХХХ-ХХХ ХХ, 11 цифр, "
            "неверная контрольная сумма)"
        )
    return errors


# --------------------------------------------------------------------------
#  Маршруты
# --------------------------------------------------------------------------
@app.route("/login", methods=["GET", "POST"])
def login():
    if session.get("user"):
        return redirect(url_for("index"))
    error = None
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        db = get_db()
        row = db.execute(
            "SELECT * FROM users WHERE username = ?", (username,)
        ).fetchone()
        if row and check_password_hash(row["password_hash"], password):
            session["user"] = username
            nxt = request.args.get("next") or url_for("index")
            if not nxt.startswith("/"):  # защита от открытого редиректа
                nxt = url_for("index")
            return redirect(nxt)
        error = "Неверный логин или пароль."
    return render_template("login.html", error=error)


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/account/password", methods=["GET", "POST"])
@login_required
def change_password():
    error = None
    success = None
    if request.method == "POST":
        current = request.form.get("current_password", "")
        new = request.form.get("new_password", "")
        new2 = request.form.get("new_password2", "")
        db = get_db()
        row = db.execute(
            "SELECT * FROM users WHERE username = ?", (session["user"],)
        ).fetchone()
        if not row or not check_password_hash(row["password_hash"], current):
            error = "Текущий пароль введён неверно."
        elif len(new) < 4:
            error = "Новый пароль слишком короткий (минимум 4 символа)."
        elif new != new2:
            error = "Новый пароль и его подтверждение не совпадают."
        elif new == current:
            error = "Новый пароль совпадает с текущим."
        else:
            db.execute(
                "UPDATE users SET password_hash = ? WHERE username = ?",
                (generate_password_hash(new), session["user"]),
            )
            db.commit()
            success = "Пароль успешно изменён."
    return render_template("change_password.html", error=error, success=success)


def _require_ftype(ftype):
    if ftype not in FORM_TYPES:
        abort(404)
    return FORM_TYPES[ftype]


@app.route("/")
@login_required
def index():
    return redirect(url_for("list_forms", ftype=DEFAULT_FORM_TYPE))


@app.route("/forms/<ftype>")
@login_required
def list_forms(ftype):
    _require_ftype(ftype)
    db = get_db()
    rows = db.execute(
        "SELECT id, patient_fio, birth_date, created_at, updated_at "
        "FROM forms WHERE form_type = ? AND deleted = 0 ORDER BY id ASC",
        (ftype,),
    ).fetchall()
    return render_template(
        "index.html", forms=rows, form_types=FORM_TYPES, current_type=ftype
    )


@app.route("/trash")
@login_required
def trash():
    db = get_db()
    rows = db.execute(
        "SELECT id, patient_fio, birth_date, form_type, created_at, updated_at "
        "FROM forms WHERE deleted = 1 ORDER BY updated_at DESC"
    ).fetchall()
    return render_template("trash.html", forms=rows, form_types=FORM_TYPES)


@app.route("/settings", methods=["GET", "POST"])
@login_required
def settings():
    success = None
    if request.method == "POST":
        set_setting("org_info", request.form.get("org_info", "").strip())
        success = "Настройки сохранены."
    return render_template(
        "settings.html",
        org_info=get_setting("org_info", ""),
        form_types=FORM_TYPES,
        success=success,
    )


@app.route("/forms/<ftype>/new", methods=["GET"])
@login_required
def form_new(ftype):
    meta = _require_ftype(ftype)
    # автоподстановка реквизитов организации из настроек
    data = {"org_info": get_setting("org_info", "")}
    return render_template(
        meta["template"], mode="new", form_id=None, data=data, form_type=ftype
    )


@app.route("/forms/<ftype>/new", methods=["POST"])
@login_required
def form_create(ftype):
    meta = _require_ftype(ftype)
    data = collect_form()
    errors = validate_form(data)
    if errors:
        return render_template(
            meta["template"], mode="new", form_id=None, data=data,
            form_type=ftype, errors=errors,
        ), 422
    db = get_db()
    cur = db.execute(
        "INSERT INTO forms (patient_fio, birth_date, form_type, created_at, updated_at, data) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (
            data.get("patient_fio", "").strip(),
            data.get("birth_date", "").strip(),
            ftype,
            now(),
            now(),
            json.dumps(data, ensure_ascii=False),
        ),
    )
    db.commit()
    return redirect(url_for("form_edit", form_id=cur.lastrowid))


@app.route("/form/<int:form_id>", methods=["GET"])
@login_required
def form_edit(form_id):
    db = get_db()
    row = db.execute("SELECT * FROM forms WHERE id = ?", (form_id,)).fetchone()
    if row is None:
        abort(404)
    ftype = row["form_type"] or DEFAULT_FORM_TYPE
    meta = _require_ftype(ftype)
    data = json.loads(row["data"] or "{}")
    return render_template(
        meta["template"], mode="edit", form_id=form_id, data=data, form_type=ftype
    )


@app.route("/form/<int:form_id>", methods=["POST"])
@login_required
def form_update(form_id):
    db = get_db()
    row = db.execute("SELECT * FROM forms WHERE id = ?", (form_id,)).fetchone()
    if row is None:
        abort(404)
    ftype = row["form_type"] or DEFAULT_FORM_TYPE
    meta = _require_ftype(ftype)
    data = collect_form()
    errors = validate_form(data)
    if errors:
        return render_template(
            meta["template"], mode="edit", form_id=form_id, data=data,
            form_type=ftype, errors=errors,
        ), 422
    db.execute(
        "UPDATE forms SET patient_fio = ?, birth_date = ?, updated_at = ?, data = ? "
        "WHERE id = ?",
        (
            data.get("patient_fio", "").strip(),
            data.get("birth_date", "").strip(),
            now(),
            json.dumps(data, ensure_ascii=False),
            form_id,
        ),
    )
    db.commit()
    return redirect(url_for("form_edit", form_id=form_id))


@app.route("/form/<int:form_id>/print", methods=["GET"])
@login_required
def form_print(form_id):
    db = get_db()
    row = db.execute("SELECT * FROM forms WHERE id = ?", (form_id,)).fetchone()
    if row is None:
        abort(404)
    ftype = row["form_type"] or DEFAULT_FORM_TYPE
    meta = _require_ftype(ftype)
    data = json.loads(row["data"] or "{}")
    return render_template(
        meta["template"], mode="print", form_id=form_id, data=data, form_type=ftype
    )


@app.route("/form/<int:form_id>/delete", methods=["POST"])
@login_required
def form_delete(form_id):
    """Мягкое удаление — карта помечается удалённой и попадает в корзину."""
    db = get_db()
    row = db.execute("SELECT form_type FROM forms WHERE id = ?", (form_id,)).fetchone()
    ftype = (row["form_type"] if row else None) or DEFAULT_FORM_TYPE
    db.execute(
        "UPDATE forms SET deleted = 1, updated_at = ? WHERE id = ?", (now(), form_id)
    )
    db.commit()
    return redirect(url_for("list_forms", ftype=ftype))


@app.route("/form/<int:form_id>/restore", methods=["POST"])
@login_required
def form_restore(form_id):
    """Восстановить карту из корзины."""
    db = get_db()
    db.execute(
        "UPDATE forms SET deleted = 0, updated_at = ? WHERE id = ?", (now(), form_id)
    )
    db.commit()
    return redirect(url_for("trash"))


@app.route("/form/<int:form_id>/purge", methods=["POST"])
@login_required
def form_purge(form_id):
    """Удалить карту навсегда (только из корзины)."""
    db = get_db()
    db.execute("DELETE FROM forms WHERE id = ? AND deleted = 1", (form_id,))
    db.commit()
    return redirect(url_for("trash"))


# --------------------------------------------------------------------------
if __name__ == "__main__":
    init_db()
    app.run(debug=True, host="127.0.0.1", port=5000)

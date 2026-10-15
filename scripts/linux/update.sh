#!/usr/bin/env bash
set -Eeuo pipefail

SERVICE="med-forms-030"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VENV="$ROOT/.venv"
OWNER="$(stat -c '%U' "$ROOT")"
WAS_ACTIVE=0
CODE_CHANGED=0
BEFORE=""

run_owner() {
  if (( EUID == 0 )) && [[ "$OWNER" != "root" ]]; then
    runuser -u "$OWNER" -- "$@"
  else
    "$@"
  fi
}

systemctl_run() {
  if (( EUID == 0 )); then systemctl "$@"; else sudo systemctl "$@"; fi
}

# Исправно ли виртуальное окружение (его интерпретатор реально запускается).
# После обновления Python (например, при апгрейде ОС) прежний интерпретатор
# исчезает, и символическая ссылка .venv/bin/python указывает "в никуда".
venv_ok() {
  [[ -x "$VENV/bin/python" ]] && "$VENV/bin/python" -c 'import sys' >/dev/null 2>&1
}

# Пересоздать .venv и переустановить зависимости.
rebuild_venv() {
  echo "Пересоздаю виртуальное окружение (.venv) ..."
  rm -rf "$VENV"
  if ! run_owner python3 -m venv "$VENV"; then
    echo "Ошибка: не удалось создать .venv. Установите: sudo apt install -y python3-venv" >&2
    exit 1
  fi
  run_owner "$VENV/bin/python" -m pip install --upgrade pip
  run_owner "$VENV/bin/pip" install -r "$ROOT/requirements.txt"
}

# Установлена ли служба systemd.
service_installed() {
  systemctl cat "$SERVICE" >/dev/null 2>&1
}

cd "$ROOT"
echo "== Обновление med-forms-030 =="
[[ -d .git ]] || { echo "Ошибка: $ROOT не является git-репозиторием." >&2; exit 1; }

# Самовосстановление окружения: если .venv отсутствует или сломан (например,
# системный Python обновился при апгрейде ОС и прежний интерпретатор исчез) —
# пересоздать окружение и перезапустить службу, даже если новых коммитов нет.
if ! venv_ok; then
  echo "Виртуальное окружение отсутствует или повреждено (возможно, после обновления Python)."
  command -v python3 >/dev/null 2>&1 || {
    echo "Ошибка: не найден python3. Установите: sudo apt install -y python3 python3-venv" >&2
    exit 1
  }
  rebuild_venv
  if service_installed; then
    echo "Перезапускаю службу $SERVICE после пересоздания окружения ..."
    systemctl_run restart "$SERVICE" || true
    systemctl_run --no-pager --full status "$SERVICE" || true
  fi
fi

# Сначала проверить GitHub. Без нового коммита приложение не перезапускается.
BEFORE="$(run_owner git -C "$ROOT" rev-parse HEAD)"
run_owner git -C "$ROOT" fetch origin
TARGET="$(run_owner git -C "$ROOT" rev-parse origin/main)"
if [[ "$BEFORE" == "$TARGET" ]]; then
  echo "Обновлений кода нет — приложение актуально (${BEFORE:0:7})."
  exit 0
fi
echo "Найдено обновление: ${BEFORE:0:7} -> ${TARGET:0:7}"

if [[ -f base.db ]]; then
  run_owner "$ROOT/scripts/linux/backup.sh"
else
  echo "base.db ещё не создана — резервное копирование пропущено."
fi

if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
  WAS_ACTIVE=1
  echo "Останавливаю службу $SERVICE ..."
  systemctl_run stop "$SERVICE"
fi

recover_on_error() {
  local code=$?
  if (( code != 0 )); then
    if (( CODE_CHANGED == 1 )); then
      echo "Ошибка обновления; возвращаю версию ${BEFORE:0:7} ..." >&2
      run_owner git -C "$ROOT" reset --hard "$BEFORE" || true
      run_owner "$ROOT/.venv/bin/pip" install -r "$ROOT/requirements.txt" || true
    fi
    if (( WAS_ACTIVE == 1 )); then systemctl_run start "$SERVICE" || true; fi
  fi
  exit "$code"
}
trap recover_on_error EXIT

run_owner git -C "$ROOT" reset --hard origin/main
CODE_CHANGED=1
run_owner "$ROOT/.venv/bin/pip" install -r "$ROOT/requirements.txt"

if (( WAS_ACTIVE == 1 )); then
  echo "Запускаю службу $SERVICE ..."
  systemctl_run start "$SERVICE"
  systemctl_run --no-pager --full status "$SERVICE" || true
fi

trap - EXIT
echo "Обновлено: ${BEFORE:0:7} -> ${TARGET:0:7}"
echo "== Обновление завершено =="

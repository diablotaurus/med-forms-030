# Развёртывание на Windows Server 2019

Скрипты для установки, запуска и обновления приложения **med-forms-030**.

| Скрипт | Назначение |
|---|---|
| `setup.ps1` / `setup.bat` | Первичная установка: окружение, зависимости, порт в брандмауэре |
| `start.ps1` / `start.bat` | Запуск сервера (waitress) в окне (Ctrl+C — остановка) |
| `update.ps1` / `update.bat` | **Ручное обновление с GitHub** (бэкап БД → git pull → зависимости → перезапуск) |
| `install-service.ps1` | Установка как службы Windows (автозапуск, фон) — нужен NSSM |
| `uninstall-service.ps1` | Удаление службы |

> Приложение обслуживается сервером **waitress** (не встроенным сервером Flask).
> Точка входа — `serve.py` (слушает `0.0.0.0:5000`, порт меняется переменной `PORT`).

---

## Шаг 1. Предусловия (один раз)

На сервере должны быть установлены:

- **Python 3.x** — <https://www.python.org/downloads/windows/> (при установке отметьте «Add Python to PATH»);
- **Git для Windows** — <https://git-scm.com/download/win>.

Проверка:

```powershell
python --version
git --version
```

## Шаг 2. Получить код с GitHub

```powershell
cd C:\
git clone https://github.com/diablotaurus/med-forms-030.git
cd med-forms-030
```

## Шаг 3. Установка

```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
```

(или дважды кликните `scripts\setup.bat`). Скрипт создаст `.venv`, поставит
зависимости и откроет порт 5000 в брандмауэре.

## Шаг 4. Запуск

**Вариант А — вручную (для проверки):**

```powershell
powershell -ExecutionPolicy Bypass -File scripts\start.ps1
```

Откройте в браузере: `http://<IP-сервера>:5000`
(локально — `http://127.0.0.1:5000`). Вход по умолчанию: **admin / admin** —
сразу смените пароль (клик по имени пользователя).

**Вариант Б — как служба Windows (рекомендуется для постоянной работы):**

1. Скачайте **NSSM**: <https://nssm.cc/download>, распакуйте `nssm.exe`
   (например, в `C:\nssm\`).
2. В окне PowerShell **от имени администратора**:

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\install-service.ps1 -NssmPath C:\nssm\nssm.exe
   ```

   Служба `med-forms-030` будет запускаться автоматически. Логи — в `logs\service.log`.
   Управление:

   ```powershell
   Restart-Service med-forms-030
   Stop-Service med-forms-030
   Start-Service med-forms-030
   ```

---

## Обновление приложения с GitHub

Когда в репозитории появились изменения — выполните на сервере:

```powershell
cd C:\med-forms-030
powershell -ExecutionPolicy Bypass -File scripts\update.ps1
```

(или дважды кликните `scripts\update.bat`). Скрипт:

1. создаёт **резервную копию** `base.db` в папке `backups\`;
2. забирает последнюю версию кода из GitHub (`git reset --hard origin/main`);
3. обновляет зависимости;
4. перезапускает службу (если установлена).

> Данные (`base.db`, `secret.key`, `backups\`, `logs\`) при обновлении
> **не затрагиваются** — они не отслеживаются git. Обновляется только код.

---

## Частые вопросы

- **Изменить порт.** Установите переменную окружения `PORT` (для службы это
  делает `install-service.ps1` параметром `-Port`). Не забудьте открыть порт
  в брандмауэре.
- **Доступ из сети.** Сервер слушает все интерфейсы (`0.0.0.0`); убедитесь, что
  порт открыт в брандмауэре (создаётся в `setup.ps1`) и доступен в вашей сети.
- **HTTPS.** Для шифрования поставьте перед приложением обратный прокси
  (IIS с ARR/URL Rewrite или nginx) и настройте сертификат.
- **Резервные копии.** Регулярно копируйте `base.db` (в нём все карты).
  `update.ps1` делает копию автоматически перед каждым обновлением.

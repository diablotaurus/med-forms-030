# Развёртывание на Windows Server 2019

Скрипты для установки, запуска и обновления приложения **med-forms-030**.

| Скрипт | Назначение |
|---|---|
| `setup.ps1` / `setup.bat` | Первичная установка: окружение, зависимости, порт в брандмауэре |
| `start.ps1` / `start.bat` | Запуск сервера (waitress) в окне (Ctrl+C — остановка) |
| `update.ps1` / `update.bat` | **Ручное обновление с GitHub** (бэкап БД → git pull → зависимости → перезапуск) |
| `backup.ps1` / `backup.bat` | Согласованная резервная копия SQLite в папку `backups\` |
| `install-task.ps1` / `install-task.bat` | **Автозапуск через Планировщик заданий (без NSSM, рекомендуется)** |
| `uninstall-task.ps1` | Удаление задачи автозапуска |
| `install-service.ps1` | Установка как службы Windows (альтернатива) — нужен NSSM |
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

**Вариант Б — автозапуск через Планировщик заданий (рекомендуется, без доп. ПО):**

В окне PowerShell **от имени администратора**:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-task.ps1
```

(или дважды кликните `scripts\install-task.bat` — он сам запросит права администратора;
другой порт: `... install-task.ps1 -Port 8080`).

Приложение будет запускаться автоматически при загрузке сервера и работать в фоне.
Управление:

```powershell
Start-ScheduledTask -TaskName med-forms-030
Stop-ScheduledTask  -TaskName med-forms-030
```

Удалить автозапуск: `scripts\uninstall-task.ps1`.

**Вариант В — как служба Windows (альтернатива, нужен NSSM):**

1. Скачайте **NSSM**: <https://nssm.cc/download> (или `winget install NSSM.NSSM`),
   распакуйте `nssm.exe` (например, в `C:\nssm\`).
2. В окне PowerShell **от имени администратора**:

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\install-service.ps1 -NssmPath C:\nssm\nssm.exe
   ```

   Служба `med-forms-030` будет запускаться автоматически. Логи — в `logs\service.log`.
   Управление: `Restart-Service med-forms-030`, `Stop-Service`, `Start-Service`.

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
4. перезапускает приложение — службу Windows или задачу Планировщика (что настроено).

> Если автозапуск настроен через **Планировщик** (`install-task.ps1`), запускайте
> `update.ps1` **от имени администратора** — иначе скрипт не сможет перезапустить
> задачу.

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
- **Резервные копии.** В `base.db` хранятся все карты. Сделать копию вручную:
  `powershell -ExecutionPolicy Bypass -File scripts\backup.ps1` (или двойной клик
  по `scripts\backup.bat`) — копия появится в папке `backups\`. Используется
  SQLite Backup API, поэтому в копию входят и последние WAL-транзакции. Можно оставлять
  только последние N копий: `scripts\backup.ps1 -Keep 30`. Перед каждым
  обновлением `update.ps1` тоже делает копию автоматически.

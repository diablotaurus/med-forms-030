# =====================================================================
#  med-forms-030 — ручное обновление с GitHub
#  Делает резервную копию базы, забирает последнюю версию кода из
#  репозитория, обновляет зависимости и перезапускает приложение —
#  службу Windows (NSSM) или задачу Планировщика, смотря что настроено.
#  Если используется автозапуск через Планировщик, запускайте этот скрипт
#  от имени администратора.
#
#  Запуск:  powershell -ExecutionPolicy Bypass -File scripts\update.ps1
#
#  ВАЖНО: локальные изменения КОДА на сервере будут перезаписаны версией
#  из GitHub. Данные (base.db, secret.key, backups, logs) НЕ затрагиваются —
#  они в .gitignore и не отслеживаются git.
# =====================================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$serviceName = "med-forms-030"
$appWasRunning = $false

Write-Host "== Обновление med-forms-030 ==" -ForegroundColor Cyan

# 0) Проверки
if (-not (Test-Path ".git")) { throw "Это не git-репозиторий. Разверните приложение через 'git clone'." }
try { git --version | Out-Null } catch { throw "git не найден в PATH." }

# Позволяет запускать обновление от SYSTEM (ночное задание Планировщика),
# даже если репозиторий принадлежит пользователю, который его устанавливал.
$env:GIT_CONFIG_COUNT = "1"
$env:GIT_CONFIG_KEY_0 = "safe.directory"
$env:GIT_CONFIG_VALUE_0 = $root

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "Команда git завершилась с ошибкой: git $GitArgs" }
}

# Сначала проверить GitHub. Если изменений нет — не трогать работающее приложение.
$before = (Invoke-Git rev-parse HEAD | Select-Object -Last 1).Trim()
Write-Host "Текущая версия: $($before.Substring(0, 7))"
Write-Host "Проверка обновлений на GitHub ..."
Invoke-Git fetch origin
$target = (Invoke-Git rev-parse origin/main | Select-Object -Last 1).Trim()
if ($before -eq $target) {
    Write-Host "Обновлений нет — приложение уже актуально." -ForegroundColor Green
    Write-Host "== Проверка обновлений завершена ==" -ForegroundColor Cyan
    return
}
Write-Host "Найдено обновление: $($before.Substring(0, 7)) -> $($target.Substring(0, 7))" -ForegroundColor Yellow

# 1) Резервная копия базы
if (Test-Path "base.db") {
    & "$PSScriptRoot\backup.ps1"
} else {
    Write-Host "Файл base.db не найден — пропускаю резервную копию."
}

# 2) Определить способ автозапуска
$svc  = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
$task = Get-ScheduledTask -TaskName $serviceName -ErrorAction SilentlyContinue
$appWasRunning = ($svc -and $svc.Status -eq "Running") -or ($task -and $task.State -eq "Running")

try {
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "Останавливаю службу $serviceName ..."
        Stop-Service $serviceName
        Start-Sleep -Seconds 1
    } elseif ($task -and $task.State -eq "Running") {
        Write-Host "Останавливаю задачу Планировщика $serviceName ..."
        Stop-ScheduledTask -TaskName $serviceName
        Start-Sleep -Seconds 1
    }

    # 3) Установить новую версию
    Invoke-Git reset --hard origin/main
    Write-Host "Обновление зависимостей ..."
    & ".\.venv\Scripts\pip.exe" install -r requirements.txt
    if ($LASTEXITCODE -ne 0) { throw "Не удалось обновить зависимости." }
    Write-Host "Обновлено: $($before.Substring(0, 7)) -> $($target.Substring(0, 7))" -ForegroundColor Green
} catch {
    Write-Host "Ошибка обновления. Возвращаю предыдущую версию $($before.Substring(0, 7)) ..." -ForegroundColor Red
    Invoke-Git reset --hard $before
    & ".\.venv\Scripts\pip.exe" install -r requirements.txt
    throw
} finally {
    if ($appWasRunning -and $svc) {
        Write-Host "Запускаю службу $serviceName ..."
        Start-Service $serviceName
    } elseif ($appWasRunning -and $task) {
        Write-Host "Запускаю задачу Планировщика $serviceName ..."
        Start-ScheduledTask -TaskName $serviceName
    }
}

if (-not $svc -and -not $task) {
    Write-Host "Автозапуск не настроен. Запустите сервер: scripts\start.ps1" -ForegroundColor Yellow
}
Write-Host "== Обновление завершено ==" -ForegroundColor Cyan

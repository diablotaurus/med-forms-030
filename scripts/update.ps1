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

Write-Host "== Обновление med-forms-030 ==" -ForegroundColor Cyan

# 0) Проверки
if (-not (Test-Path ".git")) { throw "Это не git-репозиторий. Разверните приложение через 'git clone'." }
try { git --version | Out-Null } catch { throw "git не найден в PATH." }

# 1) Резервная копия базы
if (Test-Path "base.db") {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if (-not (Test-Path "backups")) { New-Item -ItemType Directory "backups" | Out-Null }
    Copy-Item "base.db" "backups\base_$stamp.db" -Force
    Write-Host "Резервная копия базы: backups\base_$stamp.db" -ForegroundColor Green
} else {
    Write-Host "Файл base.db не найден — пропускаю резервную копию."
}

# 2) Текущая версия (для отката, если что)
$before = (git rev-parse --short HEAD)
Write-Host "Текущая версия: $before"

# 3) Определить способ автозапуска и остановить приложение на время обновления
$svc  = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
$task = Get-ScheduledTask -TaskName $serviceName -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.Status -eq "Running") {
        Write-Host "Останавливаю службу $serviceName ..."
        Stop-Service $serviceName
        Start-Sleep -Seconds 1
    }
} elseif ($task) {
    Write-Host "Останавливаю задачу Планировщика $serviceName ..."
    Stop-ScheduledTask -TaskName $serviceName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

# 4) Забрать последнюю версию из GitHub
Write-Host "Получение изменений из GitHub ..."
git fetch origin
git reset --hard origin/main
$after = (git rev-parse --short HEAD)

if ($before -eq $after) {
    Write-Host "Обновлений нет — уже последняя версия ($after)." -ForegroundColor Yellow
} else {
    Write-Host "Обновлено: $before -> $after" -ForegroundColor Green
}

# 5) Обновить зависимости
Write-Host "Обновление зависимостей ..."
& ".\.venv\Scripts\pip.exe" install -r requirements.txt

# 6) Запустить приложение обратно / подсказать запуск
if ($svc) {
    Write-Host "Запускаю службу $serviceName ..."
    Start-Service $serviceName
    Write-Host "Служба запущена." -ForegroundColor Green
} elseif ($task) {
    Write-Host "Запускаю задачу Планировщика $serviceName ..."
    Start-ScheduledTask -TaskName $serviceName
    Write-Host "Задача запущена." -ForegroundColor Green
} else {
    Write-Host "Автозапуск не настроен. Запустите сервер: scripts\start.ps1" -ForegroundColor Yellow
    Write-Host "(или настройте автозапуск: scripts\install-task.ps1)" -ForegroundColor Yellow
}

Write-Host "== Обновление завершено ==" -ForegroundColor Cyan

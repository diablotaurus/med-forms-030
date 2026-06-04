# =====================================================================
#  med-forms-030 — автозапуск через Планировщик заданий (без NSSM)
#  Создаёт задачу, которая запускает приложение при загрузке сервера
#  (даже без входа пользователя) и перезапускает его при сбое.
#
#  Запуск (от имени Администратора):
#    powershell -ExecutionPolicy Bypass -File scripts\install-task.ps1
#    powershell -ExecutionPolicy Bypass -File scripts\install-task.ps1 -Port 8080
# =====================================================================
param(
    [string]$TaskName = "med-forms-030",
    [string]$Port = "5000"
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$py   = Join-Path $root ".venv\Scripts\python.exe"

# Проверки
if (-not (Test-Path $py)) { throw "Окружение не настроено. Сначала выполните: scripts\setup.ps1" }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) { throw "Запустите PowerShell от имени администратора." }

Write-Host "Создание задачи автозапуска '$TaskName' (порт $Port) ..." -ForegroundColor Cyan

$action    = New-ScheduledTaskAction -Execute $py -Argument "serve.py $Port" -WorkingDirectory $root
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 3 `
             -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Seconds 0)

# Пересоздать, если задача уже существует
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "Задача уже существует — пересоздаю."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings `
    -Description "Веб-приложение учётных форм 030/у-Д/с и 030-ПО/у" | Out-Null

Start-ScheduledTask -TaskName $TaskName

Write-Host "Готово. Задача '$TaskName' создана и запущена." -ForegroundColor Green
Write-Host "Приложение будет стартовать автоматически при загрузке сервера." -ForegroundColor Green
Write-Host "Проверка: http://<IP-сервера>:$Port"
Write-Host "Управление: Start-ScheduledTask / Stop-ScheduledTask -TaskName $TaskName"

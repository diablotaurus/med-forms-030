# =====================================================================
#  med-forms-030 — установка как службы Windows (через NSSM)
#  Служба автоматически запускается при старте сервера и работает в фоне.
#
#  Требуется NSSM (https://nssm.cc/download). Распакуйте nssm.exe и либо
#  добавьте в PATH, либо укажите путь параметром -NssmPath.
#
#  Запуск (от имени Администратора):
#    powershell -ExecutionPolicy Bypass -File scripts\install-service.ps1
#    powershell -ExecutionPolicy Bypass -File scripts\install-service.ps1 -NssmPath C:\nssm\nssm.exe
# =====================================================================
param(
    [string]$NssmPath = "nssm",
    [string]$ServiceName = "med-forms-030",
    [string]$Port = "5000"
)
$ErrorActionPreference = "Stop"
$root   = Split-Path -Parent $PSScriptRoot
$python = Join-Path $root ".venv\Scripts\python.exe"
$serve  = Join-Path $root "serve.py"
$logdir = Join-Path $root "logs"

if (-not (Test-Path $python)) { throw "Окружение не настроено. Сначала выполните: scripts\setup.ps1" }
try { & $NssmPath version | Out-Null } catch { throw "NSSM не найден. Скачайте с https://nssm.cc/download и укажите -NssmPath." }
if (-not (Test-Path $logdir)) { New-Item -ItemType Directory $logdir | Out-Null }

Write-Host "Установка службы '$ServiceName' ..." -ForegroundColor Cyan
& $NssmPath install $ServiceName $python $serve
& $NssmPath set $ServiceName AppDirectory $root
& $NssmPath set $ServiceName DisplayName "med-forms-030 (медицинские формы 030)"
& $NssmPath set $ServiceName Description "Веб-приложение учётных форм 030/у-Д/с и 030-ПО/у"
& $NssmPath set $ServiceName Start SERVICE_AUTO_START
& $NssmPath set $ServiceName AppEnvironmentExtra "PORT=$Port"
& $NssmPath set $ServiceName AppStdout (Join-Path $logdir "service.log")
& $NssmPath set $ServiceName AppStderr (Join-Path $logdir "service.log")
& $NssmPath set $ServiceName AppRotateFiles 1
& $NssmPath set $ServiceName AppRotateBytes 1048576

& $NssmPath start $ServiceName
Write-Host "Служба '$ServiceName' установлена и запущена (порт $Port)." -ForegroundColor Green
Write-Host "Управление: Start-Service / Stop-Service / Restart-Service $ServiceName"

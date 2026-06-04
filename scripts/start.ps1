# =====================================================================
#  med-forms-030 — запуск сервера (waitress) в текущем окне
#  Запуск:  powershell -ExecutionPolicy Bypass -File scripts\start.ps1
#  Остановка: Ctrl+C
# =====================================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path ".venv\Scripts\python.exe")) {
    throw "Окружение не настроено. Сначала выполните: scripts\setup.ps1"
}

# Адрес/порт можно переопределить переменными окружения HOST и PORT
& ".\.venv\Scripts\python.exe" serve.py

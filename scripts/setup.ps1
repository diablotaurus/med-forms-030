# =====================================================================
#  med-forms-030 — первоначальная установка на сервере
#  Создаёт виртуальное окружение, ставит зависимости, открывает порт.
#  Запуск (из любой папки):  powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
# =====================================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot      # папка приложения (WebApp)
Set-Location $root
Write-Host "== Установка med-forms-030 ==" -ForegroundColor Cyan
Write-Host "Каталог приложения: $root"

# 1) Проверка Python
try { $pyv = (python --version) 2>&1 } catch { throw "Python не найден в PATH. Установите Python 3.x и повторите." }
Write-Host "Python: $pyv"

# 2) Виртуальное окружение
if (-not (Test-Path ".venv")) {
    Write-Host "Создание виртуального окружения .venv ..."
    python -m venv .venv
} else {
    Write-Host "Виртуальное окружение .venv уже существует."
}

# 3) Зависимости
Write-Host "Установка зависимостей ..."
& ".\.venv\Scripts\python.exe" -m pip install --upgrade pip
& ".\.venv\Scripts\pip.exe" install -r requirements.txt

# 4) Правило брандмауэра для порта (по умолчанию 5000)
$port = if ($env:PORT) { $env:PORT } else { "5000" }
$ruleName = "med-forms-030 (TCP $port)"
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    try {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow `
            -Protocol TCP -LocalPort $port -Profile Any | Out-Null
        Write-Host "Открыт порт $port в брандмауэре Windows."
    } catch {
        Write-Warning "Не удалось создать правило брандмауэра (нужны права администратора). Откройте порт $port вручную."
    }
} else {
    Write-Host "Правило брандмауэра для порта $port уже есть."
}

Write-Host ""
Write-Host "Готово. Запуск:  powershell -ExecutionPolicy Bypass -File scripts\start.ps1" -ForegroundColor Green
Write-Host "Либо установите как службу: scripts\install-service.ps1" -ForegroundColor Green

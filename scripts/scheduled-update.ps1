# Ночной запуск update.ps1 с журналом. Используется Планировщиком заданий.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $root "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory $logDir | Out-Null }
$log = Join-Path $logDir ("update_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

Start-Transcript -Path $log -Force | Out-Null
try {
    & "$PSScriptRoot\update.ps1"
    if ($LASTEXITCODE -ne 0) { throw "update.ps1 завершился с кодом $LASTEXITCODE" }
} catch {
    Write-Error $_
    exit 1
} finally {
    Stop-Transcript | Out-Null
    Get-ChildItem $logDir -Filter "update_*.log" | Sort-Object LastWriteTime -Descending |
        Select-Object -Skip 30 | Remove-Item -Force
}

# =====================================================================
#  med-forms-030 — удаление службы Windows (через NSSM)
#  Запуск (от имени Администратора):
#    powershell -ExecutionPolicy Bypass -File scripts\uninstall-service.ps1
# =====================================================================
param(
    [string]$NssmPath = "nssm",
    [string]$ServiceName = "med-forms-030"
)
$ErrorActionPreference = "Stop"
try { & $NssmPath version | Out-Null } catch { throw "NSSM не найден. Укажите -NssmPath." }

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host "Останавливаю службу $ServiceName ..."
    Stop-Service $ServiceName
    Start-Sleep -Seconds 1
}
& $NssmPath remove $ServiceName confirm
Write-Host "Служба '$ServiceName' удалена." -ForegroundColor Green

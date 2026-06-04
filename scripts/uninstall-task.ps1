# =====================================================================
#  med-forms-030 — удаление задачи автозапуска из Планировщика
#  Запуск (от имени Администратора):
#    powershell -ExecutionPolicy Bypass -File scripts\uninstall-task.ps1
# =====================================================================
param([string]$TaskName = "med-forms-030")
$ErrorActionPreference = "Stop"

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Stop-ScheduledTask  -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Задача '$TaskName' удалена." -ForegroundColor Green
} else {
    Write-Host "Задача '$TaskName' не найдена."
}

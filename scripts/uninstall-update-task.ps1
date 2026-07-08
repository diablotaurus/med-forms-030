$ErrorActionPreference = "Stop"
$taskName = "med-forms-030-update"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Задание $taskName удалено." -ForegroundColor Green
} else {
    Write-Host "Задание $taskName не найдено."
}

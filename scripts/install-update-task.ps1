param([string]$Time = "03:00")
$ErrorActionPreference = "Stop"
$taskName = "med-forms-030-update"
$root = Split-Path -Parent $PSScriptRoot

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principalCheck = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principalCheck.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Запустите PowerShell от имени администратора."
}
try {
    $at = [datetime]::ParseExact($Time, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
} catch {
    throw "Время должно быть в формате ЧЧ:ММ, например 03:00."
}
if (-not (Test-Path (Join-Path $root ".git"))) { throw "Приложение должно быть развёрнуто через git clone." }

$script = Join-Path $PSScriptRoot "scheduled-update.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`"" -WorkingDirectory $root
$trigger = New-ScheduledTaskTrigger -Daily -At $at
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings -Description "Ночное обновление med-forms-030 с GitHub" -Force | Out-Null
Write-Host "Задание $taskName установлено. Ежедневный запуск: $Time" -ForegroundColor Green
Write-Host "Журналы: $root\logs\update_*.log"

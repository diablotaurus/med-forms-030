# =====================================================================
#  med-forms-030 — ручная резервная копия базы данных
#  Создаёт согласованную копию base.db через SQLite Backup API.
#
#  Запуск:  powershell -ExecutionPolicy Bypass -File scripts\backup.ps1
#  Хранить только последние N копий:  ... scripts\backup.ps1 -Keep 30
# =====================================================================
param([int]$Keep = 0)   # 0 — хранить все копии; N>0 — оставить только N последних

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path "base.db")) {
    Write-Warning "Файл base.db не найден — нечего копировать."
    return
}
if (-not (Test-Path "backups")) { New-Item -ItemType Directory "backups" | Out-Null }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dest  = "backups\base_$stamp.db"
$python = ".\.venv\Scripts\python.exe"
if (-not (Test-Path $python)) { $python = "python" }
& $python "scripts\sqlite_backup.py" "base.db" $dest
if ($LASTEXITCODE -ne 0) { throw "Не удалось создать резервную копию базы." }

$size = [math]::Round((Get-Item $dest).Length / 1KB, 1)
Write-Host "Резервная копия создана: $dest ($size KB)" -ForegroundColor Green

# Ротация: оставить только последние N копий (если задано)
if ($Keep -gt 0) {
    $all = Get-ChildItem "backups\base_*.db" | Sort-Object LastWriteTime -Descending
    if ($all.Count -gt $Keep) {
        $all | Select-Object -Skip $Keep | ForEach-Object {
            Remove-Item $_.FullName -Force
            Write-Host "Удалена старая копия: $($_.Name)"
        }
    }
}

$cnt = (Get-ChildItem "backups\base_*.db" -ErrorAction SilentlyContinue).Count
Write-Host "Всего копий в папке backups\: $cnt"

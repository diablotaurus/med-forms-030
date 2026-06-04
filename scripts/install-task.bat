@echo off
chcp 65001 >nul
title med-forms-030 - автозапуск (Планировщик)
rem Самоповышение прав: если не админ — перезапустить с UAC
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-task.ps1"
echo.
pause

@echo off
chcp 65001 >nul
title med-forms-030 - резервная копия базы
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0backup.ps1"
echo.
pause

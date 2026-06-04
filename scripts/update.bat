@echo off
chcp 65001 >nul
title med-forms-030 - обновление с GitHub
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1"
echo.
pause

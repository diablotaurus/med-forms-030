@echo off
chcp 65001 >nul
title med-forms-030 - сервер
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1"
echo.
pause

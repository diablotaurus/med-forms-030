@echo off
chcp 65001 >nul
title med-forms-030 - установка
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
echo.
pause

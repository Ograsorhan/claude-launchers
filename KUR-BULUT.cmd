@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Kur.ps1" -Mode Free %*
if errorlevel 1 pause

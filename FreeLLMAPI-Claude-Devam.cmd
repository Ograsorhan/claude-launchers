@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0FreeLLMAPI-Claude.ps1" --resume %*
if errorlevel 1 pause

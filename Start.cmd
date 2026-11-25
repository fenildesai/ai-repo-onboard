@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -File "%~dp0Server.ps1"
pause

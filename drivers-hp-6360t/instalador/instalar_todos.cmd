@echo off
net session >nul 2>&1 || (powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0'" & exit /b)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar_todos.ps1"
pause

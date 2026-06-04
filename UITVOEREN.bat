@echo off
:: Vraag admin rechten aan
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Beheerdersrechten vereist. Opnieuw starten als administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Voer het script uit
powershell -ExecutionPolicy Bypass -File "%~dp0protect.ps1"

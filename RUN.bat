@echo off
:: Request admin rights if not already elevated
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run the protection script
powershell -ExecutionPolicy Bypass -File "%~dp0protect.ps1"

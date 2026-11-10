@echo off
title SPARK Centre
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0spark-update.ps1"
if exist "%~dp0site\index.html" (
  start "" "%~dp0site\index.html"
  timeout /t 3 >nul
) else (
  echo.
  echo   There's no copy of SPARK Centre on this USB yet.
  echo   Connect to the internet and run Start SPARK again.
  echo.
  pause
)

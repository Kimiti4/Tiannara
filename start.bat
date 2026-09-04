@echo off
title Tiannara Runtime Launcher
echo.
echo  TIANNARA RUNTIME LAUNCHER
echo.

if "%1"=="" (
    mix tiannara.start --profile dev
) else (
    mix tiannara.start %*
)

echo.
pause

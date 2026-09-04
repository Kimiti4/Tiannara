@echo off
set MIX_ENV=dev
set STORAGE_CONTEXT=soak
mix run scripts\soak_test.exs 72 > C:\Users\user\AppData\Local\Temp\opencode\soak72.log 2>&1
exit /b %ERRORLEVEL%

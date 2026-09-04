@echo off
setlocal enabledelayedexpansion

:: ==========================================================
:: Elixir Production Build Wrapper for Windows
:: Prevents full recompilation and enforces I/O optimization
:: ==========================================================

:: 1. Enforce Incremental Compilation (Block --force)
echo %* | findstr /C:"--force" >nul
if %errorlevel% equ 0 (
    echo [ERROR] The --force flag is blocked on Windows to prevent 10+ minute compile times.
    echo [INFO] If you absolutely must clear the cache, manually delete the _build directory.
    exit /b 1
)

:: 2. Set BEAM scheduler optimizations for this session
set "ELIXIR_ERL_OPTIONS=+sbwt none +sub true +sbt db"

:: 3. Dependency Check Bypass (If deps haven't changed)
:: Check if mix.lock has been modified in the last 5 minutes. If not, skip deps check.
forfiles /P "." /M "mix.lock" /D -0.003 >nul 2>&1
if %errorlevel% equ 0 (
    set "DEPS_FLAG=--no-deps-check"
    echo [OPTIMIZATION] Skipping dependency check (mix.lock unchanged)
) else (
    set "DEPS_FLAG="
    echo [INFO] Checking dependencies (mix.lock recently modified)
)

:: 4. Run mix with optimizations
echo [BUILD] Starting incremental compilation...
mix compile %DEPS_FLAG% %*

exit /b %errorlevel%

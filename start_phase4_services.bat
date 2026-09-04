@echo off
REM Phase 4 Backend Integration - Quick Start Script (Windows)
REM 
REM This script starts all required backend services for Phase 4 visualization
REM Run from project root directory

echo ==========================================
echo   Phase 4 Backend Integration Startup
echo ==========================================
echo.

REM Check prerequisites
echo Checking prerequisites...

where python >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found. Please install Python 3.8+
    exit /b 1
)
echo [OK] Python found

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found. Please install Node.js 18+
    exit /b 1
)
echo [OK] Node.js found

where mix >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Elixir/Mix not found. Tiannara Runtime won't start.
    echo Install from: https://elixir-lang.org/install.html
) else (
    echo [OK] Elixir/Mix found
)

echo.
echo ==========================================
echo   Starting Backend Services
echo ==========================================
echo.

REM Start Tiannara API (FastAPI)
echo Starting Tiannara API (Port 8000)...
cd tiannara_api

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating Python virtual environment...
    python -m venv venv
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install dependencies if needed
python -c "import fastapi" 2>nul
if %errorlevel% neq 0 (
    echo Installing Python dependencies...
    pip install fastapi uvicorn httpx python-dotenv
)

REM Start FastAPI server in background
start "Tiannara API" cmd /k "uvicorn main:app --reload --port 8000"
echo Tiannara API started in new window

cd ..
timeout /t 5 /nobreak >nul

REM Start Internal Dashboard (Next.js)
echo Starting Internal Dashboard (Port 3000)...
cd tiannara_internal_dashboard

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing npm dependencies...
    call npm install
)

REM Start Next.js dev server in background
start "Dashboard" cmd /k "npm run dev"
echo Dashboard started in new window

cd ..
timeout /t 5 /nobreak >nul

echo.
echo ==========================================
echo   All Services Started!
echo ==========================================
echo.
echo Service URLs:
echo   Dashboard:      http://localhost:3000
echo   API:            http://localhost:8000
echo   WebSocket:      ws://localhost:4000/socket/websocket
echo.
echo Phase 4 Demo Pages:
echo   Observatory:    http://localhost:3000/demo/observatory
echo   Meta-Control:   http://localhost:3000/demo/meta-control
echo   Universe:       http://localhost:3000/demo/universe
echo.
echo Health Checks:
echo   curl http://localhost:8000/api/v1/observatory/health
echo   curl http://localhost:8000/health
echo.
echo Note: Close the opened command windows to stop services.
echo.
echo Ready to test Phase 4 visualization components!
pause

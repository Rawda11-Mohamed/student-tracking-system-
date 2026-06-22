@echo off
echo Starting AttendFlow...

:: Start the Flask backend in a new window
start "AttendFlow Backend" cmd /k "cd /d "%~dp0" && python "backend (1).py""

:: Start the Vite frontend in a new window
start "AttendFlow Frontend" cmd /k "cd /d "%~dp0frontend" && npm run dev"

echo.
echo Both servers are starting...
echo Backend  ^> http://localhost:5001
echo Frontend ^> http://localhost:5173
echo.
echo Open http://localhost:5173 in your browser.
timeout /t 4 >nul
start "" "http://localhost:5173"

@echo off
REM Kill all running processes for ZigTrade HTMX Edition (Windows)

echo.
echo 🛑 Killing all app processes...
echo.

REM Kill Zig compiler/server
taskkill /F /IM zig.exe 2>nul

REM Wait a moment
timeout /t 2 /nobreak

echo.
echo ✅ All app processes killed successfully
echo.
pause

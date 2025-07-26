@echo off
REM Car Maintenance API - Skrypt uruchamiający (Windows)
REM Instaluje zależności i uruchamia serwer deweloperski

echo === Car Maintenance API - Setup ^& Start ===
echo.

REM Sprawdzenie czy Python jest zainstalowany
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python nie jest zainstalowany lub nie jest dostępny w PATH
    echo Zainstaluj Python 3.8+ i spróbuj ponownie
    pause
    exit /b 1
)

echo ✅ Python jest dostępny
echo.

REM Utworzenie środowiska wirtualnego (jeśli nie istnieje)
if not exist "venv" (
    echo 📦 Tworzenie środowiska wirtualnego...
    python -m venv venv
    echo ✅ Środowisko wirtualne utworzone
) else (
    echo ✅ Środowisko wirtualne już istnieje
)

echo.

REM Aktywacja środowiska wirtualnego
echo 🔧 Aktywacja środowiska wirtualnego...
call venv\Scripts\activate.bat

REM Instalacja zależności
echo 📥 Instalacja zależności...
pip install -r requirements.txt

echo.
echo ✅ Wszystkie zależności zainstalowane!
echo.

REM Sprawdzenie połączenia z bazą danych
echo 🔗 Sprawdzanie konfiguracji...
if not exist ".env" (
    echo ❌ Brak pliku .env!
    echo Skopiuj .env.example do .env i uzupełnij dane
    pause
    exit /b 1
)

echo ✅ Plik .env istnieje
echo.

REM Uruchomienie serwera
echo 🚀 Uruchamianie serwera deweloperskiego...
echo API będzie dostępne pod adresem: http://localhost:8000
echo Dokumentacja API: http://localhost:8000/docs
echo.
echo Aby zatrzymać serwer, naciśnij Ctrl+C
echo.

uvicorn main:app --host 0.0.0.0 --port 8000 --reload

pause

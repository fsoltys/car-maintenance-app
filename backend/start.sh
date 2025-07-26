#!/bin/bash

# Car Maintenance API - Skrypt uruchamiający (Windows)
# Instaluje zależności i uruchamia serwer deweloperski

echo "=== Car Maintenance API - Setup & Start ==="
echo ""

# Sprawdzenie czy Python jest zainstalowany
python --version
if [ $? -ne 0 ]; then
    echo "❌ Python nie jest zainstalowany lub nie jest dostępny w PATH"
    echo "Zainstaluj Python 3.8+ i spróbuj ponownie"
    exit 1
fi

echo "✅ Python jest dostępny"
echo ""

# Utworzenie środowiska wirtualnego (jeśli nie istnieje)
if [ ! -d "venv" ]; then
    echo "📦 Tworzenie środowiska wirtualnego..."
    python -m venv venv
    echo "✅ Środowisko wirtualne utworzone"
else
    echo "✅ Środowisko wirtualne już istnieje"
fi

echo ""

# Aktywacja środowiska wirtualnego
echo "🔧 Aktywacja środowiska wirtualnego..."
source venv/Scripts/activate

# Instalacja zależności
echo "📥 Instalacja zależności..."
pip install -r requirements.txt

echo ""
echo "✅ Wszystkie zależności zainstalowane!"
echo ""

# Sprawdzenie połączenia z bazą danych
echo "🔗 Sprawdzanie konfiguracji..."
if [ ! -f ".env" ]; then
    echo "❌ Brak pliku .env!"
    echo "Skopiuj .env.example do .env i uzupełnij dane"
    exit 1
fi

echo "✅ Plik .env istnieje"
echo ""

# Uruchomienie serwera
echo "🚀 Uruchamianie serwera deweloperskiego..."
echo "API będzie dostępne pod adresem: http://localhost:8000"
echo "Dokumentacja API: http://localhost:8000/docs"
echo ""
echo "Aby zatrzymać serwer, naciśnij Ctrl+C"
echo ""

uvicorn main:app --host 0.0.0.0 --port 8000 --reload

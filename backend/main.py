"""
FastAPI Car Maintenance Application
Podstawowa aplikacja do testowania połączenia z Azure PostgreSQL
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
import asyncpg
import os
from typing import List, Optional
from pydantic import BaseModel
from dotenv import load_dotenv
import logging

# Załaduj zmienne środowiskowe
load_dotenv()

# Konfiguracja logowania
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Inicjalizacja FastAPI
app = FastAPI(
    title="Car Maintenance API",
    description="Podstawowe API do zarządzania samochodami - wersja testowa",
    version="0.1.0"
)

# Konfiguracja CORS
allowed_origins = [
    "http://localhost:3000",
    "http://localhost:8000",
    "https://car-maintenance-backend-e0f8hzcufqe8gjf7.polandcentral-01.azurewebsites.net"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Modele Pydantic
class User(BaseModel):
    user_id: int
    username: str
    is_active: bool
    created_at: str
    updated_at: str

class DatabaseConnection:
    """Zarządzanie połączeniem z bazą danych"""
    
    def __init__(self):
        self.db_host = os.getenv("DB_HOST")
        self.db_port = int(os.getenv("DB_PORT", 5432))
        self.db_name = os.getenv("DB_NAME")
        self.db_user = os.getenv("DB_USER")
        self.db_password = os.getenv("DB_PASSWORD")
        
        # Sprawdzenie czy wszystkie zmienne są ustawione
        if not all([self.db_host, self.db_name, self.db_user, self.db_password]):
            logger.error("Brakuje wymaganych zmiennych środowiskowych dla bazy danych")
            raise ValueError("Niepełna konfiguracja bazy danych")
        
        logger.info(f"Konfiguracja bazy danych: {self.db_host}:{self.db_port}/{self.db_name}")
    
    async def get_connection(self):
        """Utwórz połączenie z bazą danych"""
        try:
            connection = await asyncpg.connect(
                host=self.db_host,
                port=self.db_port,
                database=self.db_name,
                user=self.db_user,
                password=self.db_password,
                ssl='require'  # Wymagane dla Azure PostgreSQL
            )
            logger.info("Połączenie z bazą danych nawiązane pomyślnie")
            return connection
        except Exception as e:
            logger.error(f"Błąd połączenia z bazą danych: {str(e)}")
            raise HTTPException(
                status_code=500, 
                detail=f"Nie można połączyć się z bazą danych: {str(e)}"
            )

# Instancja zarządzania bazą danych
db_manager = DatabaseConnection()

# Dependency do uzyskania połączenia z bazą danych
async def get_db_connection():
    connection = await db_manager.get_connection()
    try:
        yield connection
    finally:
        await connection.close()

# Endpointy API

@app.get("/")
async def root():
    """Podstawowy endpoint sprawdzający czy API działa"""
    return {
        "message": "Car Maintenance API działa poprawnie!",
        "version": "0.1.0",
        "environment": os.getenv("ENVIRONMENT", "production")
    }

@app.get("/health")
async def health_check():
    """Sprawdzenie stanu aplikacji i połączenia z bazą danych"""
    try:
        connection = await db_manager.get_connection()
        
        # Test prostego zapytania
        result = await connection.fetchval("SELECT 1")
        await connection.close()
        
        return {
            "status": "healthy",
            "database": "connected",
            "test_query": result
        }
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }

@app.get("/users", response_model=List[User])
async def get_users(
    limit: Optional[int] = 10,
    offset: Optional[int] = 0,
    connection: asyncpg.Connection = Depends(get_db_connection)
):
    """
    Pobierz listę użytkowników z bazy danych
    
    Args:
        limit: Maksymalna liczba rekordów (domyślnie 10)
        offset: Przesunięcie dla paginacji (domyślnie 0)
    
    Returns:
        Lista użytkowników
    """
    try:
        # Zapytanie SQL z ograniczeniem i przesunięciem
        query = """
            SELECT user_id, username, is_active, created_at, updated_at 
            FROM car_maintenance.users 
            ORDER BY created_at DESC 
            LIMIT $1 OFFSET $2
        """
        
        logger.info(f"Wykonywanie zapytania: pobieranie użytkowników (limit={limit}, offset={offset})")
        
        rows = await connection.fetch(query, limit, offset)
        
        # Konwersja wyników do modeli Pydantic
        users = []
        for row in rows:
            user = User(
                user_id=row['user_id'],
                username=row['username'],
                is_active=row['is_active'],
                created_at=row['created_at'].isoformat(),
                updated_at=row['updated_at'].isoformat()
            )
            users.append(user)
        
        logger.info(f"Znaleziono {len(users)} użytkowników")
        return users
        
    except Exception as e:
        logger.error(f"Błąd podczas pobierania użytkowników: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Błąd podczas pobierania użytkowników: {str(e)}"
        )

@app.get("/users/{user_id}", response_model=User)
async def get_user(
    user_id: int,
    connection: asyncpg.Connection = Depends(get_db_connection)
):
    """
    Pobierz konkretnego użytkownika po ID
    
    Args:
        user_id: ID użytkownika
    
    Returns:
        Dane użytkownika
    """
    try:
        query = """
            SELECT user_id, username, is_active, created_at, updated_at 
            FROM car_maintenance.users 
            WHERE user_id = $1
        """
        
        logger.info(f"Pobieranie użytkownika o ID: {user_id}")
        
        row = await connection.fetchrow(query, user_id)
        
        if not row:
            logger.warning(f"Użytkownik o ID {user_id} nie został znaleziony")
            raise HTTPException(
                status_code=404,
                detail=f"Użytkownik o ID {user_id} nie został znaleziony"
            )
        
        user = User(
            user_id=row['user_id'],
            username=row['username'],
            is_active=row['is_active'],
            created_at=row['created_at'].isoformat(),
            updated_at=row['updated_at'].isoformat()
        )
        
        logger.info(f"Znaleziono użytkownika: {user.username}")
        return user
        
    except HTTPException:
        # Przekaż HTTPException dalej bez modyfikacji
        raise
    except Exception as e:
        logger.error(f"Błąd podczas pobierania użytkownika {user_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Błąd podczas pobierania użytkownika: {str(e)}"
        )

@app.get("/users/count")
async def get_users_count(
    connection: asyncpg.Connection = Depends(get_db_connection)
):
    """
    Pobierz liczbę użytkowników w bazie danych
    
    Returns:
        Liczba użytkowników
    """
    try:
        query = "SELECT COUNT(*) FROM car_maintenance.users"
        
        logger.info("Pobieranie liczby użytkowników")
        
        count = await connection.fetchval(query)
        
        logger.info(f"Liczba użytkowników w bazie: {count}")
        
        return {
            "total_users": count,
            "active_users": await connection.fetchval(
                "SELECT COUNT(*) FROM car_maintenance.users WHERE is_active = true"
            )
        }
        
    except Exception as e:
        logger.error(f"Błąd podczas liczenia użytkowników: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Błąd podczas liczenia użytkowników: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    
    # Uruchomienie serwera deweloperskiego
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )

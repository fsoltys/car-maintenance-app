# Baza Danych Aplikacji Car Maintenance

Ten katalog zawiera schemat bazy danych PostgreSQL dla aplikacji zarządzania konserwacją pojazdów.

## Przegląd Architektury

Baza danych została zaprojektowana zgodnie z następującymi zasadami:
- **Model DBML**: Schemat bazy danych zaprojektowany w języku DBML (Database Markup Language)
- **PostgreSQL**: Pełne wykorzystanie możliwości PostgreSQL z optymalizacjami wydajności
- **Bezpieczeństwo**: Kontrola integralności danych poprzez ograniczenia i klucze obce
- **Wydajność**: Zoptymalizowane indeksy i efektywne wzorce zapytań
- **Łatwość utrzymania**: Jasny podział między schematem a danymi słownikowymi

## Struktura Bazy Danych

```
car_maintenance/
├── users                    # Konta użytkowników i autoryzacja
├── cars                     # Informacje o pojazdach
├── usage_types_dict         # Słownik typów użytkowania paliwa
├── service_category_dict    # Kategorie usług serwisowych
├── service_type_dict        # Typy usług serwisowych
├── parts                    # Katalog części zamiennych
├── fuelings                 # Historia tankowania
├── services                 # Historia serwisów
├── service_items            # Szczegóły usług serwisowych
├── service_item_parts       # Części użyte w serwisach
├── repair_todo              # Lista zadań do wykonania
├── todo_parts               # Części potrzebne do zadań
├── todo_status_dict         # Statusy zadań
├── reminders                # System przypomnień
└── reminder_type_dict       # Typy przypomnień
```

## Przegląd Plików

- `model.dbml` - Model bazy danych w języku DBML
- `01_schema.sql` - Tworzy tabele, indeksy, triggery i funkcje biznesowe
- `02_initial_data.sql` - Wstawia początkowe dane słownikowe w języku polskim

## Instrukcje Konfiguracji

### Wymagania
- PostgreSQL 13+ (zalecany Azure PostgreSQL)
- Użytkownik bazy danych z uprawnieniami CREATE
- Klient psql lub pgAdmin

### Szybka Konfiguracja
```bash
# Połącz się z instancją PostgreSQL
psql -h your-db-host -U your-username -d your-database

# Uruchom kompletną konfigurację
\i database/01_schema.sql
\i database/02_initial_data.sql
```

### Konfiguracja Krok po Kroku
```bash
# 1. Utwórz schemat i tabele
\i database/01_schema.sql

# 2. Wstaw dane początkowe
\i database/02_initial_data.sql
```

## Model Danych (DBML)

Plik `model.dbml` zawiera kompletny model relacyjny bazy danych z następującymi modułami:

### Moduł Użytkowników i Pojazdów
- **users** - Konta użytkowników z autoryzacją
- **cars** - Pojazdy należące do użytkowników z podstawowymi informacjami

### Moduł Tankowania
- **fuelings** - Historia tankowania z typami użytkowania
- **usage_types_dict** - Słownik typów jazdy (miasto, autostrada, mieszana, etc.)

### Moduł Serwisów
- **services** - Historia wykonanych serwisów
- **service_items** - Szczegółowe pozycje serwisów
- **service_item_parts** - Części użyte w serwisach
- **parts** - Katalog części zamiennych
- **service_category_dict** - Kategorie serwisów (silnik, hamulce, etc.)
- **service_type_dict** - Typy usług serwisowych

### Moduł Zadań (TODO)
- **repair_todo** - Lista zadań naprawczych do wykonania
- **todo_parts** - Części potrzebne do realizacji zadań
- **todo_status_dict** - Statusy zadań (otwarte, zrealizowane, etc.)

### Moduł Przypomnień
- **reminders** - System przypomnień o konserwacji
- **reminder_type_dict** - Typy przypomnień (wymiana oleju, przegląd, etc.)
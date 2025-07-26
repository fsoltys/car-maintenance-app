-- Car Maintenance Database - User Permissions Setup
-- Kompletne uprawnienia dla użytkownika carmaintenance
-- Uwzględnia wszystkie tabele, funkcje i przyszłe stored procedures

-- ====================
-- TWORZENIE UŻYTKOWNIKA I BAZY DANYCH
-- ====================

-- Tworzenie użytkownika carmaintenance (jeśli nie istnieje)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'carmaintenance') THEN
        CREATE USER carmaintenance WITH PASSWORD 'carmaintenance_password_2024!';
        RAISE NOTICE 'Użytkownik carmaintenance został utworzony.';
    ELSE
        RAISE NOTICE 'Użytkownik carmaintenance już istnieje.';
    END IF;
END $$;

-- Tworzenie bazy danych car_maintenance_db (jeśli nie istnieje)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'car_maintenance_db') THEN
        -- Nie można utworzyć bazy danych wewnątrz transakcji
        RAISE NOTICE 'Utwórz bazę danych ręcznie: CREATE DATABASE car_maintenance_db OWNER carmaintenance;';
    ELSE
        RAISE NOTICE 'Baza danych car_maintenance_db już istnieje.';
    END IF;
END $$;

-- ====================
-- UPRAWNIENIA NA POZIOMIE BAZY DANYCH
-- ====================

-- Podstawowe uprawnienia do bazy danych
GRANT CONNECT ON DATABASE car_maintenance_db TO carmaintenance;
GRANT USAGE ON SCHEMA public TO carmaintenance;
GRANT USAGE ON SCHEMA car_maintenance TO carmaintenance;


-- ====================
-- UPRAWNIENIA DO TABEL
-- ====================

-- Tabele główne - pełne CRUD dla danych użytkowników
GRANT SELECT, INSERT, UPDATE ON TABLE car_maintenance.users TO carmaintenance;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE car_maintenance.cars TO carmaintenance;

-- Tabele słownikowe - TYLKO ODCZYT
-- Aplikacja nie powinna modyfikować słowników w runtime
GRANT SELECT ON TABLE car_maintenance.usage_types_dict TO carmaintenance;
GRANT SELECT ON TABLE car_maintenance.service_category_dict TO carmaintenance;
GRANT SELECT ON TABLE car_maintenance.service_type_dict TO carmaintenance;
GRANT SELECT ON TABLE car_maintenance.todo_status_dict TO carmaintenance;
GRANT SELECT ON TABLE car_maintenance.reminder_type_dict TO carmaintenance;

-- Tabela części - ograniczone uprawnienia (INSERT/SELECT dla nowych części, UPDATE tylko własnych)
GRANT SELECT, INSERT, UPDATE ON TABLE car_maintenance.parts TO carmaintenance;

-- Moduł tankowania - pełne CRUD
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE car_maintenance.fuelings TO carmaintenance;

-- Moduł serwisowania - pełne CRUD
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE car_maintenance.services TO carmaintenance;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE car_maintenance.service_items TO carmaintenance;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE car_maintenance.service_item_parts TO carmaintenance;

-- Moduł zadań - pełne CRUD
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE car_maintenance.repair_todo TO carmaintenance;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE car_maintenance.todo_parts TO carmaintenance;

-- Moduł przypomnień - pełne CRUD
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE car_maintenance.reminders TO carmaintenance;

-- ====================
-- UPRAWNIENIA DO SEKWENCJI
-- ====================

-- Sekwencje dla tabel głównych
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.users_user_id_seq TO carmaintenance;
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.cars_car_id_seq TO carmaintenance;

-- Sekwencje dla tabeli części
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.parts_part_id_seq TO carmaintenance;

-- Sekwencje dla modułów aplikacyjnych
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.fuelings_fillup_id_seq TO carmaintenance;
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.services_service_id_seq TO carmaintenance;
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.service_items_item_id_seq TO carmaintenance;
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.repair_todo_todo_id_seq TO carmaintenance;
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.todo_parts_id_seq TO carmaintenance;
GRANT USAGE, SELECT ON SEQUENCE car_maintenance.reminders_rem_id_seq TO carmaintenance;

-- ====================
-- UPRAWNIENIA DO WIDOKÓW
-- ====================

-- Widoki analityczne
GRANT SELECT ON car_maintenance.car_statistics TO carmaintenance;
GRANT SELECT ON car_maintenance.pending_todos TO carmaintenance;
GRANT SELECT ON car_maintenance.upcoming_reminders TO carmaintenance;

-- ====================
-- UPRAWNIENIA DO FUNKCJI I STORED PROCEDURES
-- ====================

-- Istniejące funkcje biznesowe
GRANT EXECUTE ON FUNCTION car_maintenance.calculate_fuel_consumption(INTEGER, DATE, DATE) TO carmaintenance;
GRANT EXECUTE ON FUNCTION car_maintenance.get_maintenance_schedule(INTEGER) TO carmaintenance;
GRANT EXECUTE ON FUNCTION car_maintenance.validate_mileage_consistency() TO carmaintenance;
GRANT EXECUTE ON FUNCTION car_maintenance.cleanup_old_data(INTEGER) TO carmaintenance;

-- Funkcje systemowe (triggers)
GRANT EXECUTE ON FUNCTION car_maintenance.update_updated_at_column() TO carmaintenance;

-- ====================
-- UPRAWNIENIA DO ROZSZERZEŃ
-- ====================

-- Uprawnienia do używania rozszerzeń PostgreSQL
GRANT USAGE ON SCHEMA public TO carmaintenance;

-- ====================
-- AUTOMATYCZNE UPRAWNIENIA DLA PRZYSZŁYCH OBIEKTÓW
-- ====================

-- Automatyczne uprawnienia TYLKO do wykonywania nowych funkcji (stored procedures)
ALTER DEFAULT PRIVILEGES IN SCHEMA car_maintenance 
GRANT EXECUTE ON FUNCTIONS TO carmaintenance;

-- ====================
-- UPRAWNIENIA DO MONITOROWANIA I DIAGNOSTYKI
-- ====================

-- Ograniczone uprawnienia do metadanyche
GRANT SELECT ON information_schema.tables TO carmaintenance;
GRANT SELECT ON information_schema.columns TO carmaintenance;

-- ====================
-- UPRAWNIENIA DO BACKUPU I ODZYSKIWANIA
-- ====================

-- Uprawnienia do wykonywania kopii zapasowych
GRANT SELECT ON ALL TABLES IN SCHEMA car_maintenance TO carmaintenance;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA car_maintenance TO carmaintenance;

-- ====================
-- BEZPIECZEŃSTWO I OGRANICZENIA
-- ====================

-- Ograniczenie liczby połączeń dla użytkownika aplikacyjnego
ALTER USER carmaintenance CONNECTION LIMIT 20;

-- Ustawienie domyślnego schematu
ALTER USER carmaintenance SET search_path = car_maintenance, public;

-- Ustawienie timeout dla transakcji
ALTER USER carmaintenance SET statement_timeout = '15min';

-- Ustawienie timeout dla bezczynności
ALTER USER carmaintenance SET idle_in_transaction_session_timeout = '1h';

-- Zabezpieczenia dodatkowe
-- Zapobieganie modyfikacji ustawień systemowych
ALTER USER carmaintenance SET default_transaction_isolation = 'read committed';
ALTER USER carmaintenance SET lock_timeout = '10s';
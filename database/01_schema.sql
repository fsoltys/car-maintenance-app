-- Car Maintenance Database Schema
-- Implementation based on model.dbml
-- Complete refactoring with Polish dictionaries and optimized indexes

-- Enable UUID extension for generating unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schema for car maintenance application
CREATE SCHEMA IF NOT EXISTS car_maintenance;

-- Set search path to include our schema
SET search_path TO car_maintenance, public;

-- ====================
-- CORE TABLES
-- ====================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Cars table
CREATE TABLE IF NOT EXISTS cars (
    car_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    car_name VARCHAR(255) NOT NULL,
    fuel_capacity REAL NOT NULL CHECK (fuel_capacity > 0),
    current_mileage INTEGER NOT NULL DEFAULT 0 CHECK (current_mileage >= 0),
    first_mileage INTEGER NOT NULL DEFAULT 0 CHECK (first_mileage >= 0),
    bought_date TIMESTAMP WITH TIME ZONE NOT NULL,
    last_inspection TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cars_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT check_mileage_logical CHECK (current_mileage >= first_mileage)
);

-- ====================
-- DICTIONARY TABLES
-- ====================

-- Usage types dictionary (Polish)
CREATE TABLE IF NOT EXISTS usage_types_dict (
    usage_type SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Service category dictionary
CREATE TABLE IF NOT EXISTS service_category_dict (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Service types dictionary
CREATE TABLE IF NOT EXISTS service_type_dict (
    service_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    category_id INTEGER NOT NULL,
    CONSTRAINT fk_service_type_category FOREIGN KEY (category_id) REFERENCES service_category_dict(category_id) ON DELETE CASCADE
);

-- Parts catalog
CREATE TABLE IF NOT EXISTS parts (
    part_id SERIAL PRIMARY KEY,
    part_number VARCHAR(100),
    part_name VARCHAR(255) NOT NULL,
    manufacturer VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_part_number_manufacturer UNIQUE (part_number, manufacturer)
);

-- Todo status dictionary
CREATE TABLE IF NOT EXISTS todo_status_dict (
    status_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Reminder type dictionary
CREATE TABLE IF NOT EXISTS reminder_type_dict (
    type_id SERIAL PRIMARY KEY,
    description VARCHAR(255) UNIQUE NOT NULL
);

-- ====================
-- FUELINGS MODULE
-- ====================

-- Fuelings table
CREATE TABLE IF NOT EXISTS fuelings (
    fillup_id SERIAL PRIMARY KEY,
    car_id INTEGER NOT NULL,
    amount REAL NOT NULL CHECK (amount > 0),
    price REAL NOT NULL CHECK (price > 0),
    usage_type INTEGER NOT NULL,
    current_mileage INTEGER NOT NULL CHECK (current_mileage >= 0),
    fuel_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    price_per_liter REAL GENERATED ALWAYS AS (price / amount) STORED,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_fuelings_car_id FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE,
    CONSTRAINT fk_fuelings_usage_type FOREIGN KEY (usage_type) REFERENCES usage_types_dict(usage_type)
);

-- ====================
-- MAINTENANCE MODULE
-- ====================

-- Services table
CREATE TABLE IF NOT EXISTS services (
    service_id SERIAL PRIMARY KEY,
    car_id INTEGER NOT NULL,
    mileage INTEGER NOT NULL CHECK (mileage >= 0),
    service_date TIMESTAMP WITH TIME ZONE NOT NULL,
    cost REAL NOT NULL CHECK (cost >= 0),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_services_car_id FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE
);

-- Service items table
CREATE TABLE IF NOT EXISTS service_items (
    item_id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL,
    service_type_id INTEGER NOT NULL,
    price REAL NOT NULL CHECK (price >= 0),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_service_items_service_id FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE,
    CONSTRAINT fk_service_items_service_type_id FOREIGN KEY (service_type_id) REFERENCES service_type_dict(service_type_id)
);

-- Service item parts relationship table
CREATE TABLE IF NOT EXISTS service_item_parts (
    item_id INTEGER NOT NULL,
    part_id INTEGER NOT NULL,
    quantity REAL NOT NULL CHECK (quantity > 0),
    unit_price REAL CHECK (unit_price >= 0),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (item_id, part_id),
    CONSTRAINT fk_service_item_parts_item_id FOREIGN KEY (item_id) REFERENCES service_items(item_id) ON DELETE CASCADE,
    CONSTRAINT fk_service_item_parts_part_id FOREIGN KEY (part_id) REFERENCES parts(part_id)
);

-- ====================
-- TODO MODULE
-- ====================

-- Repair todo table
CREATE TABLE IF NOT EXISTS repair_todo (
    todo_id SERIAL PRIMARY KEY,
    car_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority INTEGER NOT NULL CHECK (priority IN (1, 2, 3)), -- 1=niskie, 2=średnie, 3=wysokie
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    status_id INTEGER NOT NULL,
    CONSTRAINT fk_repair_todo_car_id FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE,
    CONSTRAINT fk_repair_todo_status_id FOREIGN KEY (status_id) REFERENCES todo_status_dict(status_id)
);

-- Todo parts relationship table
CREATE TABLE IF NOT EXISTS todo_parts (
    id SERIAL PRIMARY KEY,
    todo_id INTEGER NOT NULL,
    part_id INTEGER NOT NULL,
    quantity REAL NOT NULL CHECK (quantity > 0),
    unit_price REAL CHECK (unit_price >= 0),
    estimated_cost REAL GENERATED ALWAYS AS (quantity * COALESCE(unit_price, 0)) STORED,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_todo_parts_todo_id FOREIGN KEY (todo_id) REFERENCES repair_todo(todo_id) ON DELETE CASCADE,
    CONSTRAINT fk_todo_parts_part_id FOREIGN KEY (part_id) REFERENCES parts(part_id),
    CONSTRAINT unique_todo_part UNIQUE (todo_id, part_id)
);

-- ====================
-- REMINDERS MODULE
-- ====================

-- Reminders table
CREATE TABLE IF NOT EXISTS reminders (
    rem_id SERIAL PRIMARY KEY,
    car_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    type_id INTEGER NOT NULL,
    day_interval INTEGER,
    mileage_interval INTEGER,
    condition_type VARCHAR(20) NOT NULL CHECK (condition_type IN ('time', 'mileage', 'both')),
    service_id INTEGER,
    todo_id INTEGER,
    part_number VARCHAR(100),
    notes TEXT,
    is_done BOOLEAN NOT NULL DEFAULT FALSE,
    due_date TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_reminders_car_id FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE,
    CONSTRAINT fk_reminders_type_id FOREIGN KEY (type_id) REFERENCES reminder_type_dict(type_id),
    CONSTRAINT fk_reminders_service_id FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE SET NULL,
    CONSTRAINT fk_reminders_todo_id FOREIGN KEY (todo_id) REFERENCES repair_todo(todo_id) ON DELETE SET NULL
);

-- ====================
-- INDEXES FOR PERFORMANCE
-- ====================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Cars indexes
CREATE INDEX IF NOT EXISTS idx_cars_user_id ON cars(user_id);
CREATE INDEX IF NOT EXISTS idx_cars_car_name ON cars(car_name);
CREATE INDEX IF NOT EXISTS idx_cars_current_mileage ON cars(current_mileage);
CREATE INDEX IF NOT EXISTS idx_cars_last_inspection ON cars(last_inspection);

-- Parts indexes
CREATE INDEX IF NOT EXISTS idx_parts_part_number ON parts(part_number);
CREATE INDEX IF NOT EXISTS idx_parts_part_name ON parts(part_name);
CREATE INDEX IF NOT EXISTS idx_parts_manufacturer ON parts(manufacturer);

-- Fuelings indexes
CREATE INDEX IF NOT EXISTS idx_fuelings_car_id ON fuelings(car_id);
CREATE INDEX IF NOT EXISTS idx_fuelings_usage_type ON fuelings(usage_type);
CREATE INDEX IF NOT EXISTS idx_fuelings_current_mileage ON fuelings(current_mileage);
CREATE INDEX IF NOT EXISTS idx_fuelings_car_mileage ON fuelings(car_id, current_mileage);

-- Services indexes
CREATE INDEX IF NOT EXISTS idx_services_car_id ON services(car_id);
CREATE INDEX IF NOT EXISTS idx_services_service_date ON services(service_date);
CREATE INDEX IF NOT EXISTS idx_services_mileage ON services(mileage);
CREATE INDEX IF NOT EXISTS idx_services_car_date ON services(car_id, service_date);
CREATE INDEX IF NOT EXISTS idx_services_car_mileage ON services(car_id, mileage);

-- Service items indexes
CREATE INDEX IF NOT EXISTS idx_service_items_service_id ON service_items(service_id);
CREATE INDEX IF NOT EXISTS idx_service_items_service_type_id ON service_items(service_type_id);

-- Service item parts indexes
CREATE INDEX IF NOT EXISTS idx_service_item_parts_item_id ON service_item_parts(item_id);
CREATE INDEX IF NOT EXISTS idx_service_item_parts_part_id ON service_item_parts(part_id);

-- Repair todo indexes
CREATE INDEX IF NOT EXISTS idx_repair_todo_car_id ON repair_todo(car_id);
CREATE INDEX IF NOT EXISTS idx_repair_todo_priority ON repair_todo(priority);
CREATE INDEX IF NOT EXISTS idx_repair_todo_is_resolved ON repair_todo(is_resolved);
CREATE INDEX IF NOT EXISTS idx_repair_todo_status_id ON repair_todo(status_id);
CREATE INDEX IF NOT EXISTS idx_repair_todo_created_at ON repair_todo(created_at);
CREATE INDEX IF NOT EXISTS idx_repair_todo_car_priority ON repair_todo(car_id, priority);
CREATE INDEX IF NOT EXISTS idx_repair_todo_car_resolved ON repair_todo(car_id, is_resolved);

-- Todo parts indexes
CREATE INDEX IF NOT EXISTS idx_todo_parts_todo_id ON todo_parts(todo_id);
CREATE INDEX IF NOT EXISTS idx_todo_parts_part_id ON todo_parts(part_id);

-- Reminders indexes
CREATE INDEX IF NOT EXISTS idx_reminders_car_id ON reminders(car_id);
CREATE INDEX IF NOT EXISTS idx_reminders_type_id ON reminders(type_id);
CREATE INDEX IF NOT EXISTS idx_reminders_due_date ON reminders(due_date);
CREATE INDEX IF NOT EXISTS idx_reminders_is_done ON reminders(is_done);
CREATE INDEX IF NOT EXISTS idx_reminders_condition_type ON reminders(condition_type);
CREATE INDEX IF NOT EXISTS idx_reminders_service_id ON reminders(service_id);
CREATE INDEX IF NOT EXISTS idx_reminders_todo_id ON reminders(todo_id);
CREATE INDEX IF NOT EXISTS idx_reminders_car_due ON reminders(car_id, due_date);
CREATE INDEX IF NOT EXISTS idx_reminders_car_done ON reminders(car_id, is_done);

-- Additional performance indexes
CREATE INDEX IF NOT EXISTS idx_fuelings_fuel_date ON fuelings(fuel_date);
CREATE INDEX IF NOT EXISTS idx_fuelings_car_date ON fuelings(car_id, fuel_date);
CREATE INDEX IF NOT EXISTS idx_parts_updated_at ON parts(updated_at);
CREATE INDEX IF NOT EXISTS idx_service_items_labor_hours ON service_items(labor_hours) WHERE labor_hours IS NOT NULL;

-- Partial indexes for common filtered queries
CREATE INDEX IF NOT EXISTS idx_repair_todo_unresolved ON repair_todo(car_id, priority, created_at) WHERE is_resolved = false;
CREATE INDEX IF NOT EXISTS idx_reminders_active ON reminders(car_id, due_date) WHERE is_done = false;
CREATE INDEX IF NOT EXISTS idx_users_active ON users(username) WHERE is_active = true;
-- ====================
-- TRIGGERS FOR AUTOMATIC TIMESTAMPS
-- ====================

-- Create trigger function for updating updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Create triggers for updated_at columns
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cars_updated_at 
    BEFORE UPDATE ON cars 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parts_updated_at 
    BEFORE UPDATE ON parts 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_services_updated_at 
    BEFORE UPDATE ON services 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ====================
-- VIEWS FOR COMMON QUERIES
-- ====================

-- View for car statistics
CREATE OR REPLACE VIEW car_statistics AS
SELECT 
    c.car_id,
    c.car_name,
    c.current_mileage,
    c.fuel_capacity,
    COUNT(DISTINCT f.fillup_id) as total_fuelings,
    COUNT(DISTINCT s.service_id) as total_services,
    COUNT(DISTINCT rt.todo_id) as total_todos,
    COUNT(DISTINCT r.rem_id) as total_reminders,
    COALESCE(SUM(f.price), 0) as total_fuel_cost,
    COALESCE(SUM(s.cost), 0) as total_service_cost
FROM cars c
LEFT JOIN fuelings f ON c.car_id = f.car_id
LEFT JOIN services s ON c.car_id = s.car_id
LEFT JOIN repair_todo rt ON c.car_id = rt.car_id
LEFT JOIN reminders r ON c.car_id = r.car_id
GROUP BY c.car_id, c.car_name, c.current_mileage, c.fuel_capacity;

-- View for pending todos by priority
CREATE OR REPLACE VIEW pending_todos AS
SELECT 
    rt.todo_id,
    rt.car_id,
    c.car_name,
    rt.title,
    rt.description,
    rt.priority,
    tsd.name as status_name,
    rt.created_at,
    CASE rt.priority
        WHEN 3 THEN 'Wysokie'
        WHEN 2 THEN 'Średnie'
        WHEN 1 THEN 'Niskie'
    END as priority_text
FROM repair_todo rt
JOIN cars c ON rt.car_id = c.car_id
JOIN todo_status_dict tsd ON rt.status_id = tsd.status_id
WHERE rt.is_resolved = false
ORDER BY rt.priority DESC, rt.created_at ASC;

-- View for upcoming reminders
CREATE OR REPLACE VIEW upcoming_reminders AS
SELECT 
    r.rem_id,
    r.car_id,
    c.car_name,
    r.name,
    rtd.description as type_description,
    r.condition_type,
    r.due_date,
    r.day_interval,
    r.mileage_interval,
    c.current_mileage,
    CASE 
        WHEN r.condition_type = 'time' AND r.due_date <= NOW() + INTERVAL '7 days' THEN true
        WHEN r.condition_type = 'mileage' AND c.current_mileage >= (c.current_mileage - COALESCE(r.mileage_interval, 0)) THEN true
        ELSE false
    END as is_due_soon
FROM reminders r
JOIN cars c ON r.car_id = c.car_id
JOIN reminder_type_dict rtd ON r.type_id = rtd.type_id
WHERE r.is_done = false
ORDER BY r.due_date ASC NULLS LAST, r.car_id;

-- ====================
-- PERFORMANCE OPTIMIZATION
-- ====================

-- Function to calculate fuel consumption
CREATE OR REPLACE FUNCTION calculate_fuel_consumption(p_car_id INTEGER, p_from_date DATE DEFAULT NULL, p_to_date DATE DEFAULT NULL)
RETURNS TABLE (
    avg_consumption REAL,
    total_distance INTEGER,
    total_fuel_amount REAL,
    total_fuel_cost REAL
) AS $$
BEGIN
    RETURN QUERY
    WITH fuel_data AS (
        SELECT 
            f.current_mileage,
            f.amount,
            f.price,
            LAG(f.current_mileage) OVER (ORDER BY f.fuel_date) as prev_mileage
        FROM fuelings f
        WHERE f.car_id = p_car_id
        AND (p_from_date IS NULL OR f.fuel_date >= p_from_date)
        AND (p_to_date IS NULL OR f.fuel_date <= p_to_date)
        ORDER BY f.fuel_date
    )
    SELECT 
        CASE 
            WHEN SUM(current_mileage - COALESCE(prev_mileage, current_mileage)) > 0 
            THEN (SUM(amount) * 100.0 / SUM(current_mileage - COALESCE(prev_mileage, current_mileage)))::REAL
            ELSE NULL
        END as avg_consumption,
        SUM(current_mileage - COALESCE(prev_mileage, current_mileage))::INTEGER as total_distance,
        SUM(amount)::REAL as total_fuel_amount,
        SUM(price)::REAL as total_fuel_cost
    FROM fuel_data
    WHERE prev_mileage IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to get maintenance schedule
CREATE OR REPLACE FUNCTION get_maintenance_schedule(p_car_id INTEGER)
RETURNS TABLE (
    reminder_id INTEGER,
    name VARCHAR,
    type_description VARCHAR,
    due_date TIMESTAMP WITH TIME ZONE,
    days_overdue INTEGER,
    mileage_overdue INTEGER,
    priority_level TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.rem_id,
        r.name,
        rtd.description,
        r.due_date,
        CASE 
            WHEN r.condition_type IN ('time', 'both') AND r.due_date < NOW() 
            THEN EXTRACT(DAYS FROM NOW() - r.due_date)::INTEGER
            ELSE 0
        END as days_overdue,
        CASE 
            WHEN r.condition_type IN ('mileage', 'both') AND c.current_mileage > (
                SELECT MAX(s.mileage) 
                FROM services s 
                WHERE s.car_id = p_car_id AND s.service_id = r.service_id
            ) + COALESCE(r.mileage_interval, 0)
            THEN c.current_mileage - ((
                SELECT MAX(s.mileage) 
                FROM services s 
                WHERE s.car_id = p_car_id AND s.service_id = r.service_id
            ) + COALESCE(r.mileage_interval, 0))
            ELSE 0
        END as mileage_overdue,
        CASE 
            WHEN (r.condition_type IN ('time', 'both') AND r.due_date < NOW() - INTERVAL '30 days') 
                OR (r.condition_type IN ('mileage', 'both') AND c.current_mileage > (
                    SELECT COALESCE(MAX(s.mileage), 0) 
                    FROM services s 
                    WHERE s.car_id = p_car_id AND s.service_id = r.service_id
                ) + COALESCE(r.mileage_interval, 0) + 5000)
            THEN 'KRYTYCZNE'
            WHEN (r.condition_type IN ('time', 'both') AND r.due_date < NOW()) 
                OR (r.condition_type IN ('mileage', 'both') AND c.current_mileage > (
                    SELECT COALESCE(MAX(s.mileage), 0) 
                    FROM services s 
                    WHERE s.car_id = p_car_id AND s.service_id = r.service_id
                ) + COALESCE(r.mileage_interval, 0))
            THEN 'PILNE'
            WHEN (r.condition_type IN ('time', 'both') AND r.due_date <= NOW() + INTERVAL '14 days') 
                OR (r.condition_type IN ('mileage', 'both') AND c.current_mileage >= (
                    SELECT COALESCE(MAX(s.mileage), 0) 
                    FROM services s 
                    WHERE s.car_id = p_car_id AND s.service_id = r.service_id
                ) + COALESCE(r.mileage_interval, 0) - 1000)
            THEN 'WKRÓTCE'
            ELSE 'PLANOWANE'
        END as priority_level
    FROM reminders r
    JOIN cars c ON r.car_id = c.car_id
    JOIN reminder_type_dict rtd ON r.type_id = rtd.type_id
    WHERE r.car_id = p_car_id AND r.is_done = false
    ORDER BY 
        CASE 
            WHEN r.condition_type IN ('time', 'both') AND r.due_date < NOW() - INTERVAL '30 days' THEN 1
            WHEN r.condition_type IN ('time', 'both') AND r.due_date < NOW() THEN 2
            WHEN r.condition_type IN ('time', 'both') AND r.due_date <= NOW() + INTERVAL '14 days' THEN 3
            ELSE 4
        END,
        r.due_date ASC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Function to validate mileage consistency
CREATE OR REPLACE FUNCTION validate_mileage_consistency()
RETURNS TABLE (
    table_name TEXT,
    record_id INTEGER,
    car_id INTEGER,
    invalid_mileage INTEGER,
    car_current_mileage INTEGER,
    issue_description TEXT
) AS $$
BEGIN
    -- Check fuelings
    RETURN QUERY
    SELECT 
        'fuelings'::TEXT,
        f.fillup_id,
        f.car_id,
        f.current_mileage,
        c.current_mileage,
        'Przebieg w tankowaniu większy niż aktualny przebieg samochodu'::TEXT
    FROM fuelings f
    JOIN cars c ON f.car_id = c.car_id
    WHERE f.current_mileage > c.current_mileage;
    
    -- Check services
    RETURN QUERY
    SELECT 
        'services'::TEXT,
        s.service_id,
        s.car_id,
        s.mileage,
        c.current_mileage,
        'Przebieg w serwisie większy niż aktualny przebieg samochodu'::TEXT
    FROM services s
    JOIN cars c ON s.car_id = c.car_id
    WHERE s.mileage > c.current_mileage;
    
    -- Check for decreasing mileage in fuelings
    RETURN QUERY
    WITH mileage_check AS (
        SELECT 
            f.fillup_id,
            f.car_id,
            f.current_mileage,
            LAG(f.current_mileage) OVER (PARTITION BY f.car_id ORDER BY f.fuel_date) as prev_mileage,
            c.current_mileage as car_mileage
        FROM fuelings f
        JOIN cars c ON f.car_id = c.car_id
    )
    SELECT 
        'fuelings'::TEXT,
        mc.fillup_id,
        mc.car_id,
        mc.current_mileage,
        mc.car_mileage,
        'Przebieg mniejszy niż w poprzednim tankowaniu'::TEXT
    FROM mileage_check mc
    WHERE mc.prev_mileage IS NOT NULL AND mc.current_mileage < mc.prev_mileage;
END;
$$ LANGUAGE plpgsql;

-- ====================
-- DATABASE MAINTENANCE PROCEDURES
-- ====================

-- Procedure to clean old data
CREATE OR REPLACE FUNCTION cleanup_old_data(p_months_to_keep INTEGER DEFAULT 24)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    cutoff_date := NOW() - (p_months_to_keep || ' months')::INTERVAL;
    
    -- Clean old resolved todos (older than specified months)
    DELETE FROM repair_todo 
    WHERE is_resolved = true 
    AND resolved_at < cutoff_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE 'Cleaned up % old resolved todos', deleted_count;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Analyze tables for query optimization
-- ANALYZE users;
-- ANALYZE cars;
-- ANALYZE usage_types_dict;
-- ANALYZE service_type_dict;
-- ANALYZE parts;
-- ANALYZE todo_status_dict;
-- ANALYZE reminder_type_dict;
-- ANALYZE fuelings;
-- ANALYZE services;
-- ANALYZE service_items;
-- ANALYZE service_item_parts;
-- ANALYZE repair_todo;
-- ANALYZE todo_parts;
-- ANALYZE reminders;

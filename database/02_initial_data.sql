-- Initial data for car maintenance database
SET search_path TO car_maintenance, public;

-- Insert usage types (expanded set)
INSERT INTO usage_types_dict (name) VALUES 
('Miasto'),
('Autostrada'),
('Mieszana'),
('Trasa')
ON CONFLICT (name) DO NOTHING;

-- Insert service categories first (required for foreign keys)
INSERT INTO service_category_dict (name) VALUES
('Obsługa okresowa'),
('Układ hamulcowy'),
('Zawieszenie'),
('Silnik'),
('Elektryka'),
('Klimatyzacja'),
('Karoseria'),
('Wydech'),
('Opony i koła'),
('Skrzynia biegów'),
('Przeglądy'),
('Pielęgnacja'),
('Pomoc drogowa'),
('Inne')
ON CONFLICT (name) DO NOTHING;

-- Insert service types with category references
INSERT INTO service_type_dict (name, description, category_id) VALUES 
-- Rutynowa konserwacja (category_id = 1)
('Wymiana oleju', 'Wymiana oleju silnikowego i filtra oleju', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Obsługa okresowa')),
('Wymiana filtra powietrza', 'Wymiana filtra powietrza silnika', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Obsługa okresowa')),
('Wymiana filtra kabinowego', 'Wymiana filtra powietrza w kabinie', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Obsługa okresowa')),
('Wymiana filtra paliwa', 'Wymiana filtra paliwa', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Obsługa okresowa')),
('Sprawdzenie akumulatora', 'Test akumulatora i układu ładowania', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Elektryka')),
('Wymiana płynu hamulcowego', 'Wymiana płynu hamulcowego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Układ hamulcowy')),
('Wymiana płynu chłodniczego', 'Wymiana płynu chłodniczego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),

--Przeglądy (category_id = 11)
('Przegląd okresowy', 'Okresowy przegląd techniczny pojazdu', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Przeglądy')),
('Diagnostyka komputerowa', 'Odczyt kodów błędów z komputera pokładowego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Przeglądy')),
('Przegląd klimatyzacji', 'Serwis i uzupełnianie czynnika chłodniczego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Klimatyzacja')),

-- Usługi opon (category_id = 9)
('Wymiana opon', 'Montaż nowych opon lub przezowanie', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Opony i koła')),
('Wyważenie kół', 'Wyważenie kół i sprawdzenie ciśnienia', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Opony i koła')),
('Naprawa opony', 'Naprawa przebicia lub uszkodzenia opony', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Opony i koła')),
('Geometria kół', 'Ustawienie geometrii zawieszenia', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Opony i koła')),

-- Usługi hamulcowe (category_id = 2)
('Inspekcja hamulców', 'Kontrola stanu klocków i tarcz hamulcowych', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Układ hamulcowy')),
('Wymiana klocków hamulcowych', 'Wymiana klocków i przetaczanie tarcz', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Układ hamulcowy')),
('Wymiana tarcz hamulcowych', 'Wymiana tarcz hamulcowych', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Układ hamulcowy')),
('Naprawa hamulców', 'Wymiana klocków, tarcz, płynu hamulcowego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Układ hamulcowy')),
('Serwis hamulca ręcznego', 'Regulacja i naprawa hamulca ręcznego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Układ hamulcowy')),

-- Usługi silnikowe (category_id = 4)
('Wymiana paska rozrządu', 'Wymiana paska rozrządu i powiązanych elementów', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),
('Naprawa silnika', 'Poważna naprawa lub remont silnika', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),
('Czyszczenie DPF/FAP', 'Czyszczenie filtra cząstek stałych', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),
('Regeneracja DPF/FAP', 'Regeneracja filtra cząstek stałych', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),
('Wymiana turbosprężarki', 'Naprawa lub wymiana turbosprężarki', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),
('Wymiana świec zapłonowych', 'Wymiana świec i elementów zapłonu', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),
('Czyszczenie układu paliwowego', 'Czyszczenie wtryskiwaczy i układu paliwowego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),
('Serwis układu chłodzenia', 'Płukanie i kontrola układu chłodzenia', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Silnik')),

-- Usługi skrzyni biegów (category_id = 10)
('Serwis skrzyni biegów', 'Wymiana oleju i kontrola skrzyni biegów', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Skrzynia biegów')),
('Naprawa skrzyni biegów', 'Naprawa lub wymiana skrzyni biegów', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Skrzynia biegów')),
('Serwis sprzęgła', 'Wymiana lub naprawa sprzęgła', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Skrzynia biegów')),

-- Usługi zawieszenia (category_id = 3)
('Serwis zawieszenia', 'Inspekcja i serwis elementów zawieszenia', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Zawieszenie')),
('Wymiana amortyzatorów', 'Wymiana amortyzatorów przednich lub tylnych', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Zawieszenie')),
('Naprawa zawieszenia pneumatycznego', 'Serwis zawieszenia pneumatycznego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Zawieszenie')),

-- Usługi elektryczne (category_id = 5)
('Naprawa układu elektrycznego', 'Diagnostyka i naprawa usterek elektrycznych', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Elektryka')),
('Wymiana alternatorów', 'Naprawa lub wymiana alternatora', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Elektryka')),
('Naprawa rozrusznika', 'Naprawa lub wymiana rozrusznika', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Elektryka')),
('Wymiana żarówek', 'Wymiana oświetlenia', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Elektryka')),
('Serwis instalacji elektrycznej', 'Kompleksowy serwis elektryki', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Elektryka')),

-- Usługi klimatyzacji (category_id = 6)
('Serwis klimatyzacji', 'Naprawa i konserwacja układu klimatyzacji', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Klimatyzacja')),
('Dezynfekcja klimatyzacji', 'Czyszczenie i dezynfekcja układu klimatyzacji', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Klimatyzacja')),
('Wymiana filtra klimatyzacji', 'Wymiana filtra układu klimatyzacji', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Klimatyzacja')),

-- Usługi karoserii (category_id = 7)
('Blacharstwo i lakierowanie', 'Naprawy blacharskie, lakiernicze i kosmetyczne', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Karoseria')),
('Naprawa szyb', 'Wymiana lub naprawa szyb', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Karoseria')),
('Naprawa zderzaka', 'Naprawa lub wymiana zderzaka', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Karoseria')),

-- Usługi układu wydechowego (category_id = 8)
('Naprawa układu wydechowego', 'Naprawa lub wymiana elementów wydechu', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Wydech')),
('Wymiana tłumika', 'Wymiana tłumika głównego lub dodatkowego', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Wydech')),
('Naprawa katalizatora', 'Naprawa lub wymiana katalizatora', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Wydech')),

-- Pielęgnacja (category_id = 12)
('Mycie i pielęgnacja', 'Mycie, woskowanie, czyszczenie wnętrza', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Pielęgnacja')),
('Czyszczenie wnętrza', 'Profesjonalne czyszczenie tapicerki', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Pielęgnacja')),
('Konserwacja skóry', 'Pielęgnacja tapicerki skórzanej', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Pielęgnacja')),

-- Inne usługi (category_id = 13/14)
('Holowanie', 'Usługa holowania pojazdu', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Pomoc drogowa')),
('Pomoc drogowa', 'Interwencja pomocy drogowej', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Pomoc drogowa')),
('Inne usługi', 'Pozostałe prace serwisowe', 
    (SELECT category_id FROM service_category_dict WHERE name = 'Inne'))
ON CONFLICT (name) DO NOTHING;

-- Insert todo status types (Polish task statuses)
INSERT INTO todo_status_dict (name) VALUES 
('Otwarte'),
('Zrealizowane'),
('Anulowane')
ON CONFLICT (name) DO NOTHING;

-- Reminder_type_dict as categories
INSERT INTO reminder_type_dict (description) VALUES 
('Silnik'),
('Układ hamulcowy'),
('Układ chłodzenia'),
('Układ elektryczny'),
('Opony i koła'),
('Skrzynia biegów'),
('Zawieszenie'),
('Klimatyzacja'),
('Dokumenty i ubezpieczenia'),
('Układ wydechowy'),
('Układ paliwowy'),
('Konserwacja ogólna'),
('Własne przypomnienia')
ON CONFLICT (description) DO NOTHING;

-- Insert sample data validation
DO $$
DECLARE
    usage_count INTEGER;
    service_count INTEGER;
    category_count INTEGER;
    todo_status_count INTEGER;
    reminder_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO usage_count FROM usage_types_dict;
    SELECT COUNT(*) INTO service_count FROM service_type_dict;
    SELECT COUNT(*) INTO category_count FROM service_category_dict;
    SELECT COUNT(*) INTO todo_status_count FROM todo_status_dict;
    SELECT COUNT(*) INTO reminder_count FROM reminder_type_dict;
    
    RAISE NOTICE 'Loaded % usage types', usage_count;
    RAISE NOTICE 'Loaded % service categories', category_count;
    RAISE NOTICE 'Loaded % service types', service_count;
    RAISE NOTICE 'Loaded % todo status types', todo_status_count;
    RAISE NOTICE 'Loaded % reminder types', reminder_count;
    
    IF usage_count = 0 OR service_count = 0 OR category_count = 0 OR todo_status_count = 0 OR reminder_count = 0 THEN
        RAISE EXCEPTION 'Failed to load required dictionary data';
    END IF;
    
    RAISE NOTICE 'All dictionary data loaded successfully!';
END
$$;

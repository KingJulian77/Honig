-- Migration 003: Kundenlesbare Bestellnummer
-- Führe diese SQL-Befehle im Supabase SQL-Editor aus.

-- Die Bestellnummer entsteht im Browser (Format HH-JJMMTT-XXXX) und wird direkt
-- mitgespeichert. Grund: anon darf Bestellungen nur schreiben, nicht lesen, und
-- kann sich die vergebene id deshalb nicht zurückgeben lassen.
ALTER TABLE orders ADD COLUMN IF NOT EXISTS ref TEXT;

CREATE INDEX IF NOT EXISTS orders_ref_idx ON orders(ref);

COMMENT ON COLUMN orders.ref IS
  'Im Browser erzeugte Bestellnummer, z. B. HH-260807-K4T9. NULL = Bestellung vor Migration 003.';

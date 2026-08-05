-- Migration 002: Warenkorb – mehrere Positionen pro Bestellung
-- Führe diese SQL-Befehle im Supabase SQL-Editor aus.

-- Einzelpositionen einer Bestellung als JSON-Array.
-- Beispiel: [{"weight":"375g","tracht":"Sommertracht","qty":2,"unitPrice":8.00}]
-- NULL bedeutet: Altbestellung von vor dem Warenkorb – dort stecken Größe und
-- Menge weiterhin im Textfeld "groesse" (z. B. "375g × 2").
ALTER TABLE orders ADD COLUMN IF NOT EXISTS items JSONB;

COMMENT ON COLUMN orders.items IS
  'Einzelpositionen: [{"weight":"375g","tracht":"Sommertracht","qty":2,"unitPrice":8.00}]. NULL = Altbestellung vor Warenkorb.';

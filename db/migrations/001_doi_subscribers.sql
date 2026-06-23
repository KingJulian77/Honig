-- Migration 001: Double-Opt-In für Newsletter-Abonnenten
-- Führe diese SQL-Befehle im Supabase SQL-Editor aus.

-- 1. Neue Spalten zur subscribers-Tabelle hinzufügen
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS confirmed BOOLEAN DEFAULT false;
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS token TEXT UNIQUE;
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS token_created_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Bestehende Abonnenten als bereits bestätigt markieren
UPDATE subscribers SET confirmed = true WHERE token IS NULL;

-- 3. Index für schnelle Token-Lookups
CREATE INDEX IF NOT EXISTS subscribers_token_idx ON subscribers(token);

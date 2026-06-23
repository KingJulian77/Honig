-- ════════════════════════════════════════════════════════════════════
-- Datenbank-Setup: Honig aus Hochkamp
-- Sicher wiederholbar – kann jederzeit erneut ausgeführt werden
-- ════════════════════════════════════════════════════════════════════


-- ── 1. Tabellen anlegen ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS stock (
  variant  TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS orders (
  id          BIGSERIAL PRIMARY KEY,
  datum       TEXT NOT NULL,
  vorname     TEXT NOT NULL DEFAULT '',
  nachname    TEXT NOT NULL DEFAULT '',
  email       TEXT,
  strasse     TEXT NOT NULL,
  hausnummer  TEXT NOT NULL,
  plz         TEXT NOT NULL,
  stadt       TEXT NOT NULL,
  groesse     TEXT NOT NULL,
  tracht      TEXT NOT NULL DEFAULT 'frühtracht',
  preis       TEXT NOT NULL,
  rabatt_code TEXT DEFAULT '',
  status      TEXT NOT NULL DEFAULT 'ausstehend',
  archived    BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscribers (
  id               BIGSERIAL PRIMARY KEY,
  email            TEXT UNIQUE NOT NULL,
  datum            TEXT NOT NULL,
  confirmed        BOOLEAN     DEFAULT false,
  token            TEXT UNIQUE,
  token_created_at TIMESTAMPTZ DEFAULT NOW(),
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS variants (
  id         BIGSERIAL PRIMARY KEY,
  weight     TEXT NOT NULL,
  tracht     TEXT NOT NULL,
  quantity   INTEGER NOT NULL DEFAULT 0,
  year       INTEGER,
  price      TEXT NOT NULL,
  image_url  TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ── 2. Fehlende Spalten ergänzen (für bestehende Datenbanken) ────────

ALTER TABLE orders      ADD COLUMN IF NOT EXISTS email       TEXT;
ALTER TABLE orders      ADD COLUMN IF NOT EXISTS tracht      TEXT DEFAULT 'frühtracht';
ALTER TABLE orders      ADD COLUMN IF NOT EXISTS rabatt_code TEXT DEFAULT '';
ALTER TABLE variants    ADD COLUMN IF NOT EXISTS image_url   TEXT;
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS confirmed        BOOLEAN     DEFAULT false;
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS token            TEXT UNIQUE;
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS token_created_at TIMESTAMPTZ DEFAULT NOW();


-- ── 3. UNIQUE Constraint auf variants (verhindert Duplikate) ─────────

-- Erst Duplikate entfernen: pro (weight, tracht) nur den ältesten Eintrag behalten
DELETE FROM variants
WHERE id NOT IN (
  SELECT MIN(id) FROM variants GROUP BY weight, tracht
);

-- Constraint setzen (sicher: wird übersprungen wenn er bereits existiert)
DO $$ BEGIN
  ALTER TABLE variants
    ADD CONSTRAINT variants_weight_tracht_unique UNIQUE (weight, tracht);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ── 4. Index für Token-Lookups ────────────────────────────────────────

CREATE INDEX IF NOT EXISTS subscribers_token_idx ON subscribers(token);


-- ── 5. Startvarianten eintragen ───────────────────────────────────────

INSERT INTO variants (weight, tracht, quantity, year, price) VALUES
  ('375g', 'Frühtracht',   0, 2025, '8,00 €'),
  ('375g', 'Sommertracht', 0, 2025, '8,00 €'),
  ('160g', 'Frühtracht',   0, 2025, '7,00 €'),
  ('160g', 'Sommertracht', 0, 2025, '7,00 €')
ON CONFLICT (weight, tracht) DO NOTHING;

-- Legacy stock-Tabelle befüllen (Fallback, wird von zahlung.html nicht mehr verwendet)
INSERT INTO stock (variant, quantity) VALUES
  ('160g-frühtracht',   0),
  ('160g-sommertracht', 0),
  ('375g-frühtracht',   0),
  ('375g-sommertracht', 0)
ON CONFLICT (variant) DO NOTHING;

-- Bestehende Abonnenten ohne Token als bereits bestätigt markieren
UPDATE subscribers SET confirmed = true WHERE token IS NULL AND confirmed = false;


-- ── 6. Row Level Security aktivieren ─────────────────────────────────

ALTER TABLE stock       ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE variants    ENABLE ROW LEVEL SECURITY;


-- ── 7. Alle alten Policies löschen ───────────────────────────────────

-- stock
DROP POLICY IF EXISTS "stock_all"           ON stock;
DROP POLICY IF EXISTS "stock_lesen"         ON stock;
DROP POLICY IF EXISTS "stock_admin"         ON stock;
DROP POLICY IF EXISTS "stock_read"          ON stock;
DROP POLICY IF EXISTS "stock_write"         ON stock;
DROP POLICY IF EXISTS "stock_update_anon"   ON stock;
DROP POLICY IF EXISTS "stock_authenticated" ON stock;

-- orders
DROP POLICY IF EXISTS "orders_all"           ON orders;
DROP POLICY IF EXISTS "orders_insert"        ON orders;
DROP POLICY IF EXISTS "orders_admin"         ON orders;
DROP POLICY IF EXISTS "orders_authenticated" ON orders;
DROP POLICY IF EXISTS "orders_read"          ON orders;
DROP POLICY IF EXISTS "orders_write"         ON orders;

-- subscribers
DROP POLICY IF EXISTS "subscribers_all"           ON subscribers;
DROP POLICY IF EXISTS "subscribers_insert"        ON subscribers;
DROP POLICY IF EXISTS "subscribers_admin"         ON subscribers;
DROP POLICY IF EXISTS "subscribers_authenticated" ON subscribers;
DROP POLICY IF EXISTS "subscribers_read"          ON subscribers;
DROP POLICY IF EXISTS "subscribers_write"         ON subscribers;
DROP POLICY IF EXISTS "subscribers_anon"          ON subscribers;

-- variants
DROP POLICY IF EXISTS "variants_all"         ON variants;
DROP POLICY IF EXISTS "variants_read"        ON variants;
DROP POLICY IF EXISTS "variants_write"       ON variants;
DROP POLICY IF EXISTS "variants_lesen"       ON variants;
DROP POLICY IF EXISTS "variants_admin"       ON variants;
DROP POLICY IF EXISTS "variants_update_anon" ON variants;


-- ── 8. Neue Policies anlegen ──────────────────────────────────────────

-- stock: nur lesen (Checkout nutzt jetzt variants; Admin verwaltet alles)
CREATE POLICY "stock_lesen" ON stock FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "stock_admin" ON stock FOR ALL    TO authenticated        USING (true) WITH CHECK (true);

-- orders: Besucher dürfen Bestellungen aufgeben; Admin sieht und verwaltet alles
CREATE POLICY "orders_insert" ON orders FOR INSERT TO anon         WITH CHECK (true);
CREATE POLICY "orders_admin"  ON orders FOR ALL    TO authenticated USING (true) WITH CHECK (true);

-- subscribers:
--   anon  → INSERT (anmelden), SELECT (Token prüfen), UPDATE (Bestätigung setzen)
--   admin → alles
CREATE POLICY "subscribers_anon"  ON subscribers FOR SELECT TO anon         USING (true);
CREATE POLICY "subscribers_insert" ON subscribers FOR INSERT TO anon         WITH CHECK (true);
CREATE POLICY "subscribers_update" ON subscribers FOR UPDATE TO anon         USING (true) WITH CHECK (true);
CREATE POLICY "subscribers_admin"  ON subscribers FOR ALL    TO authenticated USING (true) WITH CHECK (true);

-- variants:
--   anon  → lesen (Produktseite) + aktualisieren (Bestandsabzug im Checkout)
--   admin → alles (Varianten anlegen, löschen, Bestand setzen)
CREATE POLICY "variants_lesen"       ON variants FOR SELECT TO anon         USING (true);
CREATE POLICY "variants_update_anon" ON variants FOR UPDATE TO anon         USING (true) WITH CHECK (true);
CREATE POLICY "variants_admin"       ON variants FOR ALL    TO authenticated USING (true) WITH CHECK (true);


-- ── 9. Storage Bucket für Variantenbilder ─────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('variant-images', 'variant-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "variant_images_all" ON storage.objects;
CREATE POLICY "variant_images_all" ON storage.objects
  FOR ALL TO anon, authenticated
  USING  (bucket_id = 'variant-images')
  WITH CHECK (bucket_id = 'variant-images');

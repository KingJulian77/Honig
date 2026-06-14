-- ── Bestand ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stock (
  variant   TEXT PRIMARY KEY,
  quantity  INTEGER NOT NULL DEFAULT 0
);
INSERT INTO stock (variant, quantity) VALUES
  ('160g-frühtracht',   0),
  ('160g-sommertracht', 0),
  ('375g-frühtracht',   0),
  ('375g-sommertracht', 0)
ON CONFLICT (variant) DO NOTHING;

-- ── Bestellungen ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id         BIGSERIAL PRIMARY KEY,
  datum      TEXT NOT NULL,
  vorname    TEXT NOT NULL DEFAULT '',
  nachname   TEXT NOT NULL DEFAULT '',
  strasse    TEXT NOT NULL,
  hausnummer TEXT NOT NULL,
  plz        TEXT NOT NULL,
  stadt      TEXT NOT NULL,
  groesse    TEXT NOT NULL,
  tracht     TEXT NOT NULL DEFAULT 'frühtracht',
  preis      TEXT NOT NULL,
  status     TEXT NOT NULL DEFAULT 'ausstehend',
  archived   BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Newsletter-Abonnenten ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscribers (
  id         BIGSERIAL PRIMARY KEY,
  email      TEXT UNIQUE NOT NULL,
  datum      TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Varianten (dynamisch verwaltbar) ────────────────────────
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
-- Bei bestehenden Deployments: ALTER TABLE variants ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ── Supabase Storage für Variantenbilder ──────────────────────
-- Im Supabase SQL-Editor ausführen:
-- INSERT INTO storage.buckets (id, name, public)
--   VALUES ('variant-images', 'variant-images', true)
--   ON CONFLICT (id) DO UPDATE SET public = true;
-- CREATE POLICY "variant_images_all" ON storage.objects
--   FOR ALL TO anon
--   USING (bucket_id = 'variant-images')
--   WITH CHECK (bucket_id = 'variant-images');
INSERT INTO variants (weight, tracht, quantity, year, price) VALUES
  ('375g', 'Frühtracht',   0, 2025, '8,00 €'),
  ('375g', 'Sommertracht', 0, 2025, '8,00 €'),
  ('160g', 'Frühtracht',   0, 2025, '7,00 €'),
  ('160g', 'Sommertracht', 0, 2025, '7,00 €')
ON CONFLICT DO NOTHING;

-- ── Sicherheit (Row Level Security) ──────────────────────────
ALTER TABLE stock       ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE variants    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stock_all"       ON stock       FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "orders_all"      ON orders      FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "subscribers_all" ON subscribers FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "variants_all"    ON variants    FOR ALL TO anon USING (true) WITH CHECK (true);

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

-- ── Sicherheit (Row Level Security) ──────────────────────────
ALTER TABLE stock       ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stock_all"       ON stock       FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "orders_all"      ON orders      FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "subscribers_all" ON subscribers FOR ALL TO anon USING (true) WITH CHECK (true);

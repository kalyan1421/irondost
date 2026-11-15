-- IronDost: schema additions for the market-gap plan (replica-architect output).
--
-- STATUS: design draft. Tested ONLY on a throwaway PostgreSQL 14 cluster that had IronDost's seven
-- existing migrations applied (see replica/architecture.md, "How this was tested"). It has NOT been applied
-- to any real database, is NOT in apps/api/prisma/schema.prisma, and no application code uses it.
-- Turning it into a real migration means: add the models to schema.prisma, run `prisma migrate dev`, then
-- hand-keep the two triggers and the partial indexes (Prisma does not model them).
--
-- Conventions copied from the existing migrations: snake_case plural tables, Postgres enums named in
-- PascalCase, TIMESTAMP(3) for times (Prisma's UTC default), money as integer paise, UUID keys.
-- The skill's default is timestamptz; new tables use TIMESTAMP(3) on purpose so they match every existing table.

BEGIN;

-- ---------------------------------------------------------------- enums
CREATE TYPE "DeliverySpeed"    AS ENUM ('STANDARD', 'EXPRESS');
CREATE TYPE "OrderKind"        AS ENUM ('ITEMISED', 'QUICK');
CREATE TYPE "IssueCategory"    AS ENUM ('LATE', 'MISSED_PICKUP', 'DAMAGED', 'MISSING_ITEM', 'QUALITY', 'BILLING', 'RIDER', 'OTHER');
CREATE TYPE "IssueStatus"      AS ENUM ('OPEN', 'ACKNOWLEDGED', 'RESOLVED', 'REJECTED');
CREATE TYPE "AdjustmentStatus" AS ENUM ('PENDING_CUSTOMER', 'APPROVED', 'DECLINED', 'EXPIRED');
CREATE TYPE "WalletTxKind"     AS ENUM ('TOPUP', 'BONUS', 'SPEND', 'REFUND', 'ADJUSTMENT', 'EXPIRY');
CREATE TYPE "ReferralStatus"   AS ENUM ('PENDING', 'QUALIFIED', 'REWARDED', 'REJECTED');
CREATE TYPE "PhotoKind"        AS ENUM ('PICKUP', 'DELIVERY', 'ISSUE');

-- ---------------------------------------------------------------- 1. express delivery and quick orders
-- Admin-editable rules sit in the existing single-row business_settings, like every other rule.
ALTER TABLE business_settings
  ADD COLUMN express_enabled              BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN express_fee_percent          INTEGER NOT NULL DEFAULT 0 CHECK (express_fee_percent BETWEEN 0 AND 100),
  ADD COLUMN express_fee_min_paise        INTEGER NOT NULL DEFAULT 0 CHECK (express_fee_min_paise >= 0),
  ADD COLUMN express_min_turnaround_hours INTEGER NOT NULL DEFAULT 8 CHECK (express_min_turnaround_hours > 0),
  ADD CONSTRAINT express_faster_than_standard CHECK (express_min_turnaround_hours <= min_turnaround_hours);

ALTER TABLE orders
  ADD COLUMN delivery_speed       "DeliverySpeed" NOT NULL DEFAULT 'STANDARD',
  ADD COLUMN express_fee_paise    INTEGER NOT NULL DEFAULT 0 CHECK (express_fee_paise >= 0),
  ADD COLUMN kind                 "OrderKind" NOT NULL DEFAULT 'ITEMISED',
  ADD COLUMN estimated_weight_kg  NUMERIC(5,1) CHECK (estimated_weight_kg > 0),
  ADD COLUMN estimated_pieces     INTEGER CHECK (estimated_pieces > 0),
  ADD COLUMN reschedule_count     SMALLINT NOT NULL DEFAULT 0 CHECK (reschedule_count BETWEEN 0 AND 3),
  ADD CONSTRAINT express_fee_only_when_express CHECK (delivery_speed = 'EXPRESS' OR express_fee_paise = 0);

-- ---------------------------------------------------------------- 2. configurable pickup windows
-- Replaces the fixed MORNING / NOON / EVENING enum over time. Orders keep the old enum columns until the app
-- reads the new ones; a later migration drops the enum.
CREATE TABLE slot_templates (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code         TEXT NOT NULL UNIQUE,
  label        TEXT NOT NULL,
  start_time   TIME NOT NULL,
  end_time     TIME NOT NULL,
  days_of_week SMALLINT[] NOT NULL DEFAULT '{1,2,3,4,5,6,7}',
  capacity     INTEGER CHECK (capacity IS NULL OR capacity > 0),
  is_active    BOOLEAN NOT NULL DEFAULT true,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT slot_window_valid CHECK (end_time > start_time),
  CONSTRAINT slot_days_valid  CHECK (cardinality(days_of_week) > 0 AND days_of_week <@ ARRAY[1,2,3,4,5,6,7]::smallint[])
);

INSERT INTO slot_templates (code, label, start_time, end_time, sort_order) VALUES
  ('MORNING', 'Morning', '07:00', '11:00', 1),
  ('NOON',    'Noon',    '11:00', '16:00', 2),
  ('EVENING', 'Evening', '16:00', '20:00', 3);

ALTER TABLE orders
  ADD COLUMN pickup_slot_id   UUID REFERENCES slot_templates(id) ON DELETE RESTRICT,
  ADD COLUMN delivery_slot_id UUID REFERENCES slot_templates(id) ON DELETE RESTRICT;

UPDATE orders o SET
  pickup_slot_id   = (SELECT id FROM slot_templates WHERE code = o.pickup_slot::text),
  delivery_slot_id = (SELECT id FROM slot_templates WHERE code = o.delivery_slot::text);

CREATE INDEX orders_pickup_slot_idx   ON orders (pickup_date, pickup_slot_id);
CREATE INDEX orders_delivery_slot_idx ON orders (delivery_date, delivery_slot_id);

-- ---------------------------------------------------------------- 2b. trust-core settings
-- Placeholders: how long staff have to first reply to a report, and how long a customer has to answer a price
-- change. The owner sets the real numbers in the admin; these defaults only make the columns non-null.
ALTER TABLE business_settings
  ADD COLUMN issue_first_response_hours INTEGER NOT NULL DEFAULT 4  CHECK (issue_first_response_hours > 0),
  ADD COLUMN adjustment_expiry_hours    INTEGER NOT NULL DEFAULT 12 CHECK (adjustment_expiry_hours > 0);

-- ---------------------------------------------------------------- 3. problem reports with a response clock
-- ON DELETE: an issue belongs to its order (CASCADE); the author is kept (RESTRICT) because users are
-- soft-deleted and anonymised, never hard-deleted.
CREATE TABLE order_issues (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id              UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  customer_id           UUID NOT NULL REFERENCES users(id)  ON DELETE RESTRICT,
  category              "IssueCategory" NOT NULL,
  description           TEXT NOT NULL CHECK (length(description) BETWEEN 1 AND 2000),
  photo_urls            TEXT[] NOT NULL DEFAULT '{}' CHECK (cardinality(photo_urls) <= 5),
  status                "IssueStatus" NOT NULL DEFAULT 'OPEN',
  first_response_due_at TIMESTAMP(3) NOT NULL,
  acknowledged_at       TIMESTAMP(3),
  resolved_at           TIMESTAMP(3),
  resolution_note       TEXT,
  handled_by_id         UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at            TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT resolved_has_time CHECK ((status IN ('RESOLVED','REJECTED')) = (resolved_at IS NOT NULL))
);
CREATE INDEX order_issues_order_idx   ON order_issues (order_id);
CREATE INDEX order_issues_cust_idx    ON order_issues (customer_id, created_at DESC);
CREATE INDEX order_issues_queue_idx   ON order_issues (status, created_at);
-- The job that raises "no reply yet" alerts reads only this small slice.
CREATE INDEX order_issues_overdue_idx ON order_issues (first_response_due_at) WHERE status = 'OPEN';

CREATE TABLE order_issue_messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id    UUID NOT NULL REFERENCES order_issues(id) ON DELETE CASCADE,
  author_id   UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  from_staff  BOOLEAN NOT NULL,
  body        TEXT NOT NULL CHECK (length(body) BETWEEN 1 AND 2000),
  created_at  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX order_issue_messages_idx ON order_issue_messages (issue_id, created_at);

-- ---------------------------------------------------------------- 4. customer approval of price changes
CREATE TABLE order_adjustments (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id         UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status           "AdjustmentStatus" NOT NULL DEFAULT 'PENDING_CUSTOMER',
  reason           TEXT NOT NULL CHECK (length(reason) BETWEEN 1 AND 500),
  old_total_paise  INTEGER NOT NULL CHECK (old_total_paise >= 0),
  new_total_paise  INTEGER NOT NULL CHECK (new_total_paise >= 0),
  items_before     JSONB NOT NULL,
  items_after      JSONB NOT NULL,
  requested_by_id  UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  decided_at       TIMESTAMP(3),
  expires_at       TIMESTAMP(3) NOT NULL,
  created_at       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT decided_has_time CHECK ((status = 'PENDING_CUSTOMER') = (decided_at IS NULL))
);
-- At most one open question per order: the database, not the UI, stops two staff from stacking changes.
CREATE UNIQUE INDEX one_pending_adjustment_per_order ON order_adjustments (order_id) WHERE status = 'PENDING_CUSTOMER';
CREATE INDEX order_adjustments_expiry_idx ON order_adjustments (expires_at) WHERE status = 'PENDING_CUSTOMER';

-- ---------------------------------------------------------------- 5. pickup condition photos and after-delivery rating
CREATE TABLE order_photos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  kind        "PhotoKind" NOT NULL,
  url         TEXT NOT NULL,
  taken_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX order_photos_order_idx ON order_photos (order_id, kind);

CREATE TABLE order_feedback (
  order_id   UUID PRIMARY KEY REFERENCES orders(id) ON DELETE CASCADE,
  rating     SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment    TEXT CHECK (comment IS NULL OR length(comment) <= 1000),
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------- 6. care options and add-ons
CREATE TABLE catalog_addons (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES catalog_categories(id) ON DELETE RESTRICT,
  name        TEXT NOT NULL,
  price_paise INTEGER NOT NULL CHECK (price_paise >= 0),
  is_active   BOOLEAN NOT NULL DEFAULT true,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- The name and price are copied onto the order, like order_items, so a later price edit cannot change a placed order.
CREATE TABLE order_addons (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  addon_id    UUID REFERENCES catalog_addons(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  price_paise INTEGER NOT NULL CHECK (price_paise >= 0)
);
CREATE INDEX order_addons_order_idx ON order_addons (order_id);

-- ---------------------------------------------------------------- 7. first-order offers with free garments
ALTER TABLE promotions ADD COLUMN first_order_only BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE promotion_free_items (
  promotion_id    UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  catalog_item_id UUID NOT NULL REFERENCES catalog_items(id) ON DELETE RESTRICT,
  quantity        INTEGER NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (promotion_id, catalog_item_id)
);

-- ---------------------------------------------------------------- 8. stored value (wallet) and referrals
-- Decide with an accountant what kind of stored value this is before building the UI (see architecture.md).
CREATE TABLE wallet_packs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label       TEXT NOT NULL,
  pay_paise   INTEGER NOT NULL CHECK (pay_paise > 0),
  bonus_paise INTEGER NOT NULL DEFAULT 0 CHECK (bonus_paise >= 0),
  is_active   BOOLEAN NOT NULL DEFAULT true,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wallet_accounts (
  user_id       UUID PRIMARY KEY REFERENCES users(id) ON DELETE RESTRICT,
  balance_paise INTEGER NOT NULL DEFAULT 0 CHECK (balance_paise >= 0),
  updated_at    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Append-only ledger. Positive amounts add money, negative amounts spend it.
CREATE TABLE wallet_transactions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  kind                "WalletTxKind" NOT NULL,
  amount_paise        INTEGER NOT NULL CHECK (amount_paise <> 0),
  balance_after_paise INTEGER,
  order_id            UUID REFERENCES orders(id) ON DELETE RESTRICT,
  payment_id          UUID REFERENCES payments(id) ON DELETE RESTRICT,
  idempotency_key     TEXT NOT NULL UNIQUE,
  note                TEXT,
  created_by_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at          TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT sign_matches_kind CHECK (
    (kind IN ('TOPUP','BONUS','REFUND') AND amount_paise > 0) OR
    (kind IN ('SPEND','EXPIRY')         AND amount_paise < 0) OR
    (kind = 'ADJUSTMENT')
  )
);
CREATE INDEX wallet_tx_user_idx ON wallet_transactions (user_id, created_at DESC);

-- The balance is changed only by inserting ledger rows. The account row is locked by the UPDATE, so two
-- concurrent spends queue up, and the CHECK on balance_paise makes an overspend fail the whole insert.
CREATE FUNCTION wallet_apply_tx() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO wallet_accounts (user_id) VALUES (NEW.user_id) ON CONFLICT (user_id) DO NOTHING;
  UPDATE wallet_accounts
     SET balance_paise = balance_paise + NEW.amount_paise, updated_at = CURRENT_TIMESTAMP
   WHERE user_id = NEW.user_id
   RETURNING balance_paise INTO NEW.balance_after_paise;
  RETURN NEW;
END $$;
CREATE TRIGGER wallet_tx_apply BEFORE INSERT ON wallet_transactions FOR EACH ROW EXECUTE FUNCTION wallet_apply_tx();

CREATE FUNCTION wallet_tx_forbid_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'wallet_transactions is append-only; add a reversing row instead';
END $$;
CREATE TRIGGER wallet_tx_no_update BEFORE UPDATE OR DELETE ON wallet_transactions FOR EACH ROW EXECUTE FUNCTION wallet_tx_forbid_change();

ALTER TABLE users
  ADD COLUMN referral_code TEXT UNIQUE,
  ADD COLUMN whatsapp_opt_in_at TIMESTAMP(3);

CREATE TABLE referrals (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id        UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  referee_id         UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
  status             "ReferralStatus" NOT NULL DEFAULT 'PENDING',
  qualifying_order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  rewarded_at        TIMESTAMP(3),
  created_at         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT no_self_referral CHECK (referrer_id <> referee_id)
);
CREATE INDEX referrals_referrer_idx ON referrals (referrer_id);

COMMIT;

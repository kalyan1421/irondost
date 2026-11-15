-- IronDost: FIRST MIGRATION, the "trust core" (problem reports with a response clock, and customer approval of price changes).
--
-- GENERATED from replica/schema.sql (sections 2b, 3 and 4 plus their enums) so the first build can ship alone.
-- If you edit the full file, regenerate this one. STATUS: design draft; tested only on a throwaway PostgreSQL 14
-- cluster with IronDost's seven existing migrations applied (see replica/plans/backend-plan.md). Not applied anywhere,
-- not in schema.prisma, unused by any application code.

BEGIN;

-- enums
CREATE TYPE "IssueCategory"    AS ENUM ('LATE', 'MISSED_PICKUP', 'DAMAGED', 'MISSING_ITEM', 'QUALITY', 'BILLING', 'RIDER', 'OTHER');
CREATE TYPE "IssueStatus"      AS ENUM ('OPEN', 'ACKNOWLEDGED', 'RESOLVED', 'REJECTED');
CREATE TYPE "AdjustmentStatus" AS ENUM ('PENDING_CUSTOMER', 'APPROVED', 'DECLINED', 'EXPIRED');

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

COMMIT;

-- AlterTable: how many times the customer moved a booked pickup or delivery time, the key of the latest move so a retry
-- after a lost response is not counted twice, and when the pickup last moved (dispatch ignores offers made before it:
-- they were for another time). Additive: existing orders start at 0 with nothing recorded.
ALTER TABLE "orders" ADD COLUMN "reschedule_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "reschedule_key" TEXT,
ADD COLUMN "reschedule_hash" TEXT,
ADD COLUMN "pickup_rescheduled_at" TIMESTAMP(3);

-- The app allows 2 moves per order; the database allows up to 10 so the limit can change without a migration.
ALTER TABLE "orders" ADD CONSTRAINT "orders_reschedule_count_check" CHECK ("reschedule_count" BETWEEN 0 AND 10);
ALTER TABLE "orders" ADD CONSTRAINT "orders_reschedule_key_check" CHECK (("reschedule_key" IS NULL) = ("reschedule_hash" IS NULL));

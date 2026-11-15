-- AlterTable: the travel charge rule an order was booked under, so a later settings change never alters it, and whether
-- staff kept the charge when cancelling after the partner had already travelled. Additive: both rule columns stay NULL
-- on existing orders, which then keep the delivery fee they were booked with and have no free-from threshold.
ALTER TABLE "orders" ADD COLUMN "travel_charge_paise_rule" INTEGER,
ADD COLUMN "travel_free_from_paise_rule" INTEGER,
ADD COLUMN "travel_charge_kept" BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE "orders" ADD CONSTRAINT "orders_travel_rule_check" CHECK (
  ("travel_charge_paise_rule" IS NULL OR "travel_charge_paise_rule" >= 0)
  AND ("travel_free_from_paise_rule" IS NULL OR "travel_free_from_paise_rule" >= 0)
);

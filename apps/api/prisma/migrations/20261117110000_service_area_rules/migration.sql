-- Service area rules for LB Nagar: pickup capacity per window, why staff overrode the area or a full window on a phone order,
-- and the waiting list of customers who asked to be told when we start serving them. Additive: nothing existing is changed
-- except that the one settings row gets the default capacity of 8 pickups per window (set it empty in admin for no cap).

-- Pickups one window (a pickup date and slot) can hold. Null = no cap.
ALTER TABLE "business_settings" ADD COLUMN "pickup_capacity_per_slot" INTEGER DEFAULT 8;
ALTER TABLE "business_settings" ADD CONSTRAINT "business_settings_pickup_capacity_check" CHECK ("pickup_capacity_per_slot" IS NULL OR "pickup_capacity_per_slot" > 0);

-- Staff phone orders: the typed reason for an address outside the area, and for booking into a full window.
ALTER TABLE "orders" ADD COLUMN "area_override_reason" TEXT,
ADD COLUMN "capacity_override_reason" TEXT;
ALTER TABLE "orders" ADD CONSTRAINT "orders_area_override_reason_check" CHECK ("area_override_reason" IS NULL OR char_length(btrim("area_override_reason")) >= 5);
ALTER TABLE "orders" ADD CONSTRAINT "orders_capacity_override_reason_check" CHECK ("capacity_override_reason" IS NULL OR char_length(btrim("capacity_override_reason")) >= 5);

-- CreateTable
CREATE TABLE "area_interest" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "address_id" UUID,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "pincode" TEXT NOT NULL,
    "locality" TEXT NOT NULL,
    "distance_km" DOUBLE PRECISION,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notified_at" TIMESTAMP(3),

    CONSTRAINT "area_interest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "area_interest_pincode_idx" ON "area_interest"("pincode");

-- CreateIndex
CREATE INDEX "area_interest_created_at_idx" ON "area_interest"("created_at" DESC);

-- AddForeignKey
ALTER TABLE "area_interest" ADD CONSTRAINT "area_interest_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "area_interest" ADD CONSTRAINT "area_interest_address_id_fkey" FOREIGN KEY ("address_id") REFERENCES "addresses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- One open request per customer and PIN code, however often they tap. Once staff have told them, they can ask again.
CREATE UNIQUE INDEX "area_interest_open_user_pincode_key" ON "area_interest"("user_id", "pincode") WHERE "notified_at" IS NULL;

-- A map position is both coordinates or neither, and a distance is never negative.
ALTER TABLE "area_interest" ADD CONSTRAINT "area_interest_position_check" CHECK (("latitude" IS NULL) = ("longitude" IS NULL));
ALTER TABLE "area_interest" ADD CONSTRAINT "area_interest_distance_check" CHECK ("distance_km" IS NULL OR "distance_km" >= 0);

-- Service area: radius around a hub and/or a PIN code allow-list.
ALTER TABLE "business_settings" ADD COLUMN     "service_center_latitude" DOUBLE PRECISION,
ADD COLUMN     "service_center_longitude" DOUBLE PRECISION,
ADD COLUMN     "service_pincodes" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "service_radius_km" DOUBLE PRECISION;

-- The radius needs its centre, and a centre without a radius means nothing.
ALTER TABLE "business_settings" ADD CONSTRAINT "business_settings_service_radius_check" CHECK (
  ("service_center_latitude" IS NULL AND "service_center_longitude" IS NULL AND "service_radius_km" IS NULL)
  OR ("service_center_latitude" IS NOT NULL AND "service_center_longitude" IS NOT NULL AND "service_radius_km" > 0)
);

-- Idempotent order placement.
ALTER TABLE "orders" ADD COLUMN     "idempotency_hash" TEXT,
ADD COLUMN     "idempotency_key" TEXT;

ALTER TABLE "orders" ADD CONSTRAINT "orders_idempotency_check" CHECK (("idempotency_key" IS NULL) = ("idempotency_hash" IS NULL));

-- CreateIndex
CREATE UNIQUE INDEX "orders_customer_id_idempotency_key_key" ON "orders"("customer_id", "idempotency_key");

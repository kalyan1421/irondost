-- CreateEnum
CREATE TYPE "PushDeliveryStatus" AS ENUM ('SENT', 'PARTIAL', 'FAILED', 'NO_DEVICE');

-- CreateTable
CREATE TABLE "push_deliveries" (
    "id" UUID NOT NULL,
    "notification_id" UUID,
    "user_id" UUID NOT NULL,
    "app" "ClientApp" NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "status" "PushDeliveryStatus" NOT NULL,
    "device_count" INTEGER NOT NULL DEFAULT 0,
    "failed_count" INTEGER NOT NULL DEFAULT 0,
    "error_code" TEXT,
    "order_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "handled_at" TIMESTAMP(3),
    "handled_by_id" UUID,

    CONSTRAINT "push_deliveries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "push_deliveries_created_at_idx" ON "push_deliveries"("created_at" DESC);

-- CreateIndex
CREATE INDEX "push_deliveries_notification_id_idx" ON "push_deliveries"("notification_id");

-- CreateIndex
CREATE INDEX "push_deliveries_user_id_idx" ON "push_deliveries"("user_id");

-- CreateIndex
CREATE INDEX "push_deliveries_order_id_idx" ON "push_deliveries"("order_id");

-- AddForeignKey
ALTER TABLE "push_deliveries" ADD CONSTRAINT "push_deliveries_notification_id_fkey" FOREIGN KEY ("notification_id") REFERENCES "notifications"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "push_deliveries" ADD CONSTRAINT "push_deliveries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "push_deliveries" ADD CONSTRAINT "push_deliveries_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "push_deliveries" ADD CONSTRAINT "push_deliveries_handled_by_id_fkey" FOREIGN KEY ("handled_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Status and counts always agree: SENT reached every device, FAILED reached none, PARTIAL some, NO_DEVICE had none to try.
ALTER TABLE "push_deliveries" ADD CONSTRAINT "push_deliveries_status_counts" CHECK (
  "device_count" >= 0 AND "failed_count" >= 0 AND "failed_count" <= "device_count" AND (
    ("status" = 'SENT' AND "device_count" > 0 AND "failed_count" = 0) OR
    ("status" = 'PARTIAL' AND "failed_count" > 0 AND "failed_count" < "device_count") OR
    ("status" = 'FAILED' AND "device_count" > 0 AND "failed_count" = "device_count") OR
    ("status" = 'NO_DEVICE' AND "device_count" = 0)
  )
);

-- The admin list and the dashboard count only look at alerts that did not arrive and nobody has followed up yet.
CREATE INDEX "push_deliveries_open_problems_idx" ON "push_deliveries"("created_at" DESC) WHERE "status" <> 'SENT' AND "handled_at" IS NULL;

-- AlterTable: what the customer wants the workshop to know about their clothes, added when booking. Separate from
-- orders.instructions, which is for the pickup partner. Additive: existing orders have no care note.
ALTER TABLE "orders" ADD COLUMN "care_note" TEXT;
ALTER TABLE "orders" ADD CONSTRAINT "orders_care_note_check" CHECK ("care_note" IS NULL OR char_length("care_note") BETWEEN 1 AND 500);

-- CreateTable: photos of the clothes. A photo is uploaded before the order exists, so order_id stays empty until the
-- order is placed. Several photos can wait unattached (a draft); each can be attached to one order only.
CREATE TABLE "order_care_photos" (
    "id" UUID NOT NULL,
    "order_id" UUID,
    "user_id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_care_photos_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "order_care_photos_key_key" ON "order_care_photos"("key");

-- CreateIndex
CREATE INDEX "order_care_photos_order_id_idx" ON "order_care_photos"("order_id");

-- CreateIndex
CREATE INDEX "order_care_photos_user_id_created_at_idx" ON "order_care_photos"("user_id", "created_at");

-- AddForeignKey
ALTER TABLE "order_care_photos" ADD CONSTRAINT "order_care_photos_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_care_photos" ADD CONSTRAINT "order_care_photos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

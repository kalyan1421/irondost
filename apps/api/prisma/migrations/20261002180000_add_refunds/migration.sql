-- Refunds: money returned to a customer, always with a note they see in the app.
CREATE TYPE "RefundMethod" AS ENUM ('RAZORPAY', 'CASH', 'BANK_TRANSFER');

CREATE TYPE "RefundStatus" AS ENUM ('PENDING', 'PROCESSED', 'FAILED');

-- Running total of PENDING + PROCESSED refunds; a FAILED refund gives its amount back.
ALTER TABLE "orders" ADD COLUMN     "refunded_paise" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "orders" ADD CONSTRAINT "orders_refunded_within_paid"
  CHECK ("refunded_paise" >= 0 AND "refunded_paise" <= "paid_paise");

-- CreateTable
CREATE TABLE "refunds" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "payment_id" UUID,
    "method" "RefundMethod" NOT NULL,
    "status" "RefundStatus" NOT NULL DEFAULT 'PENDING',
    "amount_paise" INTEGER NOT NULL,
    "note" TEXT NOT NULL,
    "razorpay_refund_id" TEXT,
    "failure_reason" TEXT,
    "created_by_id" UUID,
    "processed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "refunds_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "refunds"
  ADD CONSTRAINT "refunds_amount_positive" CHECK ("amount_paise" > 0),
  ADD CONSTRAINT "refunds_note_length" CHECK (char_length(btrim("note")) BETWEEN 3 AND 500),
  -- A Razorpay refund names the payment and the gateway refund; money returned by hand names neither.
  ADD CONSTRAINT "refunds_razorpay_shape" CHECK (
    ("method" = 'RAZORPAY' AND "payment_id" IS NOT NULL AND "razorpay_refund_id" IS NOT NULL)
    OR ("method" <> 'RAZORPAY' AND "payment_id" IS NULL AND "razorpay_refund_id" IS NULL)
  );

-- CreateIndex
CREATE UNIQUE INDEX "refunds_razorpay_refund_id_key" ON "refunds"("razorpay_refund_id");

-- CreateIndex
CREATE INDEX "refunds_order_id_created_at_idx" ON "refunds"("order_id", "created_at");

-- CreateIndex
CREATE INDEX "refunds_payment_id_idx" ON "refunds"("payment_id");

-- AddForeignKey
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_payment_id_fkey" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AlterTable: the remedy agreed on a resolved report, and the refund that pays it when it is paid as a refund.
ALTER TABLE "order_issues" ADD COLUMN "compensation_paise" INTEGER,
ADD COLUMN "refund_id" UUID;

-- CreateIndex
CREATE INDEX "order_issues_refund_id_idx" ON "order_issues"("refund_id");

-- AddForeignKey
ALTER TABLE "order_issues" ADD CONSTRAINT "order_issues_refund_id_fkey" FOREIGN KEY ("refund_id") REFERENCES "refunds"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- A remedy only exists on a closed report, is never negative, and a linked refund implies a recorded amount.
ALTER TABLE "order_issues" ADD CONSTRAINT issue_compensation_valid CHECK (
  (compensation_paise IS NULL OR compensation_paise BETWEEN 0 AND 10000000)
  AND (compensation_paise IS NULL OR status IN ('RESOLVED','REJECTED'))
  AND (refund_id IS NULL OR compensation_paise IS NOT NULL)
);

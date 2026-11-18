-- CreateEnum
CREATE TYPE "AdjustmentStatus" AS ENUM ('PENDING_CUSTOMER', 'APPROVED', 'DECLINED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "IssueCategory" AS ENUM ('LATE', 'MISSED_PICKUP', 'DAMAGED', 'MISSING_ITEM', 'QUALITY', 'BILLING', 'RIDER', 'OTHER');

-- CreateEnum
CREATE TYPE "IssueStatus" AS ENUM ('OPEN', 'ACKNOWLEDGED', 'RESOLVED', 'REJECTED');

-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "revision" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "business_settings" ADD COLUMN     "adjustment_expiry_hours" INTEGER NOT NULL DEFAULT 12,
ADD COLUMN     "issue_first_response_hours" INTEGER;

-- CreateTable
CREATE TABLE "order_adjustments" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "status" "AdjustmentStatus" NOT NULL DEFAULT 'PENDING_CUSTOMER',
    "reason" TEXT NOT NULL,
    "old_total_paise" INTEGER NOT NULL,
    "new_total_paise" INTEGER NOT NULL,
    "subtotal_paise" INTEGER NOT NULL,
    "discount_paise" INTEGER NOT NULL,
    "delivery_fee_paise" INTEGER NOT NULL,
    "base_revision" INTEGER NOT NULL,
    "items_before" JSONB NOT NULL,
    "items_after" JSONB NOT NULL,
    "requested_by_id" UUID NOT NULL,
    "decided_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "order_adjustments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_issues" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "category" "IssueCategory" NOT NULL,
    "description" TEXT NOT NULL,
    "photo_urls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "IssueStatus" NOT NULL DEFAULT 'OPEN',
    "first_response_due_at" TIMESTAMP(3),
    "acknowledged_at" TIMESTAMP(3),
    "resolved_at" TIMESTAMP(3),
    "resolution_note" TEXT,
    "handled_by_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "order_issues_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_issue_messages" (
    "id" UUID NOT NULL,
    "issue_id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "from_staff" BOOLEAN NOT NULL,
    "body" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_issue_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "order_adjustments_order_id_created_at_idx" ON "order_adjustments"("order_id", "created_at");

-- CreateIndex
CREATE INDEX "order_adjustments_status_expires_at_idx" ON "order_adjustments"("status", "expires_at");

-- CreateIndex
CREATE INDEX "order_issues_order_id_idx" ON "order_issues"("order_id");

-- CreateIndex
CREATE INDEX "order_issues_customer_id_created_at_idx" ON "order_issues"("customer_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "order_issues_status_first_response_due_at_idx" ON "order_issues"("status", "first_response_due_at");

-- CreateIndex
CREATE INDEX "order_issue_messages_issue_id_created_at_idx" ON "order_issue_messages"("issue_id", "created_at");

-- AddForeignKey
ALTER TABLE "order_adjustments" ADD CONSTRAINT "order_adjustments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_adjustments" ADD CONSTRAINT "order_adjustments_requested_by_id_fkey" FOREIGN KEY ("requested_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_issues" ADD CONSTRAINT "order_issues_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_issues" ADD CONSTRAINT "order_issues_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_issues" ADD CONSTRAINT "order_issues_handled_by_id_fkey" FOREIGN KEY ("handled_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_issue_messages" ADD CONSTRAINT "order_issue_messages_issue_id_fkey" FOREIGN KEY ("issue_id") REFERENCES "order_issues"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_issue_messages" ADD CONSTRAINT "order_issue_messages_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- One open request per order, even across concurrent staff requests.
CREATE UNIQUE INDEX one_pending_adjustment_per_order ON order_adjustments(order_id) WHERE status = 'PENDING_CUSTOMER';
ALTER TABLE order_adjustments ADD CONSTRAINT adjustment_decision_time CHECK ((status = 'PENDING_CUSTOMER') = (decided_at IS NULL));
ALTER TABLE order_adjustments ADD CONSTRAINT adjustment_valid_totals CHECK (old_total_paise >= 0 AND new_total_paise >= 0 AND length(reason) BETWEEN 1 AND 500);
ALTER TABLE business_settings ADD CONSTRAINT trust_clock_ranges CHECK (adjustment_expiry_hours BETWEEN 1 AND 168 AND (issue_first_response_hours IS NULL OR issue_first_response_hours BETWEEN 1 AND 168));
ALTER TABLE order_issues ADD CONSTRAINT issue_resolved_time CHECK ((status IN ('RESOLVED','REJECTED')) = (resolved_at IS NOT NULL));
ALTER TABLE order_issues ADD CONSTRAINT issue_description_photos CHECK (length(description) BETWEEN 1 AND 2000 AND cardinality(photo_urls) <= 5);
ALTER TABLE order_issue_messages ADD CONSTRAINT message_length CHECK (length(body) BETWEEN 1 AND 2000);
-- AlterTable
ALTER TABLE "order_issues" ADD COLUMN     "overdue_notified_at" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "issue_photos" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "issue_photos_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "issue_photos_key_key" ON "issue_photos"("key");

-- CreateIndex
CREATE INDEX "issue_photos_user_id_created_at_idx" ON "issue_photos"("user_id", "created_at");

-- AddForeignKey
ALTER TABLE "issue_photos" ADD CONSTRAINT "issue_photos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


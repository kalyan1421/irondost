-- AlterTable: the time the money was confirmed, kept apart from updated_at, which moves on any later write.
ALTER TABLE "payments" ADD COLUMN "captured_at" TIMESTAMP(3);

-- Existing captured payments: the last write is the best record of when they were captured.
UPDATE "payments" SET "captured_at" = "updated_at" WHERE "status" = 'CAPTURED';

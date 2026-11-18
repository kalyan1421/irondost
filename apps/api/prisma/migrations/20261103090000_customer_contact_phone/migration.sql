-- AlterTable: a customer can add the number the pickup partner should call at checkout, without an SMS code.
-- It is kept apart from the verified, unique `phone` so a mistyped number can never take over someone else's sign-in.
ALTER TABLE "users" ADD COLUMN "contact_phone" TEXT;

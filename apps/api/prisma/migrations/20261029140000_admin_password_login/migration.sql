-- AlterTable: admins can sign in with email + password (scrypt hash), not only a phone code.
ALTER TABLE "users" ADD COLUMN "password_hash" TEXT;

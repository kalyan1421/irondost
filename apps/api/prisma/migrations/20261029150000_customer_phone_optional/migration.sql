-- AlterTable: a customer who signs in with Google has no phone until they add and verify one (needed before ordering).
ALTER TABLE "users" ALTER COLUMN "phone" DROP NOT NULL;

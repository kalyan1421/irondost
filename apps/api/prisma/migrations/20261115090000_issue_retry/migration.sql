ALTER TABLE "order_issues" ADD COLUMN "request_key" TEXT;
ALTER TABLE "order_issues" ADD COLUMN "request_hash" TEXT;
CREATE UNIQUE INDEX "order_issues_customer_id_request_key_key" ON "order_issues"("customer_id", "request_key");
ALTER TABLE "order_issues" ADD CONSTRAINT "issue_request_pair" CHECK ((request_key IS NULL) = (request_hash IS NULL));

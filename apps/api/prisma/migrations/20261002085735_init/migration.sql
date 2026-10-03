-- CreateEnum
CREATE TYPE "Role" AS ENUM ('CUSTOMER', 'DRIVER', 'ADMIN', 'SUPER_ADMIN');

-- CreateEnum
CREATE TYPE "TimeSlot" AS ENUM ('MORNING', 'NOON', 'EVENING');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'PICKUP_ASSIGNED', 'PICKED_UP', 'PROCESSING', 'READY_FOR_DELIVERY', 'DELIVERY_ASSIGNED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "OrderSource" AS ENUM ('CUSTOMER_APP', 'ADMIN');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('COD', 'ONLINE');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'REFUNDED');

-- CreateEnum
CREATE TYPE "PaymentProvider" AS ENUM ('RAZORPAY', 'CASH');

-- CreateEnum
CREATE TYPE "PaymentRecordStatus" AS ENUM ('CREATED', 'CAPTURED', 'FAILED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "DispatchLeg" AS ENUM ('PICKUP', 'DELIVERY');

-- CreateEnum
CREATE TYPE "OfferStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ItemUnit" AS ENUM ('PIECE', 'PAIR', 'SET', 'KG');

-- CreateEnum
CREATE TYPE "DiscountType" AS ENUM ('PERCENT', 'FLAT');

-- CreateEnum
CREATE TYPE "DevicePlatform" AS ENUM ('ANDROID', 'IOS', 'WEB');

-- CreateEnum
CREATE TYPE "ClientApp" AS ENUM ('CUSTOMER', 'PARTNER', 'ADMIN');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "firebase_uid" TEXT,
    "phone" TEXT NOT NULL,
    "name" TEXT,
    "email" TEXT,
    "role" "Role" NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "driver_profiles" (
    "user_id" UUID NOT NULL,
    "vehicle_number" TEXT,
    "license_number" TEXT,
    "is_online" BOOLEAN NOT NULL DEFAULT false,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "location_updated_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "driver_profiles_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "devices" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "fcm_token" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "app" "ClientApp" NOT NULL,
    "last_seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "devices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "addresses" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "label" TEXT NOT NULL DEFAULT 'Home',
    "house_no" TEXT NOT NULL,
    "building" TEXT,
    "street" TEXT NOT NULL,
    "area" TEXT,
    "landmark" TEXT,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "pincode" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "addresses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "catalog_categories" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "image_url" TEXT,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "catalog_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "catalog_items" (
    "id" UUID NOT NULL,
    "category_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "unit" "ItemUnit" NOT NULL DEFAULT 'PIECE',
    "price_paise" INTEGER NOT NULL,
    "offer_price_paise" INTEGER,
    "image_url" TEXT,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "catalog_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "promotions" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "discount_type" "DiscountType" NOT NULL,
    "discount_value" INTEGER NOT NULL,
    "min_order_paise" INTEGER NOT NULL DEFAULT 0,
    "max_discount_paise" INTEGER,
    "per_customer_limit" INTEGER,
    "valid_from" TIMESTAMP(3) NOT NULL,
    "valid_to" TIMESTAMP(3) NOT NULL,
    "image_url" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "promotions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "banners" (
    "id" UUID NOT NULL,
    "image_url" TEXT NOT NULL,
    "title" TEXT,
    "link_url" TEXT,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "banners_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "orders" (
    "id" UUID NOT NULL,
    "order_number" TEXT NOT NULL,
    "customer_id" UUID NOT NULL,
    "status" "OrderStatus" NOT NULL DEFAULT 'PENDING',
    "source" "OrderSource" NOT NULL DEFAULT 'CUSTOMER_APP',
    "created_by_id" UUID,
    "pickup_date" DATE NOT NULL,
    "pickup_slot" "TimeSlot" NOT NULL,
    "delivery_date" DATE NOT NULL,
    "delivery_slot" "TimeSlot" NOT NULL,
    "pickup_address_id" UUID,
    "delivery_address_id" UUID,
    "pickup_address" JSONB NOT NULL,
    "delivery_address" JSONB NOT NULL,
    "pickup_latitude" DOUBLE PRECISION,
    "pickup_longitude" DOUBLE PRECISION,
    "delivery_latitude" DOUBLE PRECISION,
    "delivery_longitude" DOUBLE PRECISION,
    "instructions" TEXT,
    "subtotal_paise" INTEGER NOT NULL,
    "discount_paise" INTEGER NOT NULL DEFAULT 0,
    "delivery_fee_paise" INTEGER NOT NULL DEFAULT 0,
    "total_paise" INTEGER NOT NULL,
    "paid_paise" INTEGER NOT NULL DEFAULT 0,
    "promotion_id" UUID,
    "promo_code" TEXT,
    "payment_method" "PaymentMethod" NOT NULL,
    "payment_status" "PaymentStatus" NOT NULL DEFAULT 'UNPAID',
    "pickup_driver_id" UUID,
    "delivery_driver_id" UUID,
    "dispatch_failed_at" TIMESTAMP(3),
    "cancel_reason" TEXT,
    "picked_up_at" TIMESTAMP(3),
    "delivered_at" TIMESTAMP(3),
    "cancelled_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "catalog_item_id" UUID,
    "name" TEXT NOT NULL,
    "unit" "ItemUnit" NOT NULL,
    "unit_price_paise" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "line_total_paise" INTEGER NOT NULL,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_events" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "from_status" "OrderStatus",
    "to_status" "OrderStatus" NOT NULL,
    "actor_id" UUID,
    "actor_role" "Role",
    "note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dispatch_offers" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "driver_id" UUID NOT NULL,
    "leg" "DispatchLeg" NOT NULL,
    "round" INTEGER NOT NULL,
    "status" "OfferStatus" NOT NULL DEFAULT 'PENDING',
    "distance_km" DOUBLE PRECISION,
    "offered_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "responded_at" TIMESTAMP(3),

    CONSTRAINT "dispatch_offers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "provider" "PaymentProvider" NOT NULL,
    "status" "PaymentRecordStatus" NOT NULL DEFAULT 'CREATED',
    "amount_paise" INTEGER NOT NULL,
    "razorpay_order_id" TEXT,
    "razorpay_payment_id" TEXT,
    "collected_by_id" UUID,
    "raw" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "data" JSONB,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "business_settings" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "min_order_paise" INTEGER NOT NULL DEFAULT 0,
    "delivery_fee_paise" INTEGER NOT NULL DEFAULT 0,
    "free_delivery_above_paise" INTEGER,
    "min_turnaround_hours" INTEGER NOT NULL DEFAULT 20,
    "booking_cutoff_minutes" INTEGER NOT NULL DEFAULT 60,
    "max_advance_days" INTEGER NOT NULL DEFAULT 30,
    "dispatch_lead_minutes" INTEGER NOT NULL DEFAULT 60,
    "dispatch_batch_size" INTEGER NOT NULL DEFAULT 3,
    "offer_timeout_seconds" INTEGER NOT NULL DEFAULT 20,
    "dispatch_retry_minutes" INTEGER NOT NULL DEFAULT 5,
    "driver_max_active_legs" INTEGER NOT NULL DEFAULT 3,
    "driver_location_max_age_minutes" INTEGER NOT NULL DEFAULT 15,
    "support_phone" TEXT,
    "support_email" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "business_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "app_versions" (
    "id" UUID NOT NULL,
    "app" "ClientApp" NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "min_version" TEXT NOT NULL,
    "latest_version" TEXT NOT NULL,
    "store_url" TEXT,
    "message" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "app_versions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL,
    "actor_id" UUID,
    "action" TEXT NOT NULL,
    "entity" TEXT NOT NULL,
    "entity_id" TEXT,
    "data" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_firebase_uid_key" ON "users"("firebase_uid");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE INDEX "users_role_is_active_idx" ON "users"("role", "is_active");

-- CreateIndex
CREATE INDEX "driver_profiles_is_online_idx" ON "driver_profiles"("is_online");

-- CreateIndex
CREATE UNIQUE INDEX "devices_fcm_token_key" ON "devices"("fcm_token");

-- CreateIndex
CREATE INDEX "devices_user_id_idx" ON "devices"("user_id");

-- CreateIndex
CREATE INDEX "addresses_user_id_idx" ON "addresses"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "catalog_categories_slug_key" ON "catalog_categories"("slug");

-- CreateIndex
CREATE INDEX "catalog_items_category_id_is_active_sort_order_idx" ON "catalog_items"("category_id", "is_active", "sort_order");

-- CreateIndex
CREATE UNIQUE INDEX "promotions_code_key" ON "promotions"("code");

-- CreateIndex
CREATE UNIQUE INDEX "orders_order_number_key" ON "orders"("order_number");

-- CreateIndex
CREATE INDEX "orders_customer_id_created_at_idx" ON "orders"("customer_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "orders_status_pickup_date_idx" ON "orders"("status", "pickup_date");

-- CreateIndex
CREATE INDEX "orders_pickup_driver_id_status_idx" ON "orders"("pickup_driver_id", "status");

-- CreateIndex
CREATE INDEX "orders_delivery_driver_id_status_idx" ON "orders"("delivery_driver_id", "status");

-- CreateIndex
CREATE INDEX "orders_created_at_idx" ON "orders"("created_at" DESC);

-- CreateIndex
CREATE INDEX "order_items_order_id_idx" ON "order_items"("order_id");

-- CreateIndex
CREATE INDEX "order_events_order_id_created_at_idx" ON "order_events"("order_id", "created_at");

-- CreateIndex
CREATE INDEX "dispatch_offers_driver_id_status_idx" ON "dispatch_offers"("driver_id", "status");

-- CreateIndex
CREATE INDEX "dispatch_offers_order_id_leg_status_idx" ON "dispatch_offers"("order_id", "leg", "status");

-- CreateIndex
CREATE UNIQUE INDEX "dispatch_offers_order_id_leg_driver_id_round_key" ON "dispatch_offers"("order_id", "leg", "driver_id", "round");

-- CreateIndex
CREATE UNIQUE INDEX "payments_razorpay_order_id_key" ON "payments"("razorpay_order_id");

-- CreateIndex
CREATE UNIQUE INDEX "payments_razorpay_payment_id_key" ON "payments"("razorpay_payment_id");

-- CreateIndex
CREATE INDEX "payments_order_id_idx" ON "payments"("order_id");

-- CreateIndex
CREATE INDEX "notifications_user_id_created_at_idx" ON "notifications"("user_id", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "app_versions_app_platform_key" ON "app_versions"("app", "platform");

-- CreateIndex
CREATE INDEX "audit_logs_entity_entity_id_idx" ON "audit_logs"("entity", "entity_id");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at" DESC);

-- AddForeignKey
ALTER TABLE "driver_profiles" ADD CONSTRAINT "driver_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "catalog_items" ADD CONSTRAINT "catalog_items_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "catalog_categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_pickup_driver_id_fkey" FOREIGN KEY ("pickup_driver_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_delivery_driver_id_fkey" FOREIGN KEY ("delivery_driver_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_pickup_address_id_fkey" FOREIGN KEY ("pickup_address_id") REFERENCES "addresses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_delivery_address_id_fkey" FOREIGN KEY ("delivery_address_id") REFERENCES "addresses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_promotion_id_fkey" FOREIGN KEY ("promotion_id") REFERENCES "promotions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_catalog_item_id_fkey" FOREIGN KEY ("catalog_item_id") REFERENCES "catalog_items"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_events" ADD CONSTRAINT "order_events_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_events" ADD CONSTRAINT "order_events_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispatch_offers" ADD CONSTRAINT "dispatch_offers_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispatch_offers" ADD CONSTRAINT "dispatch_offers_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_collected_by_id_fkey" FOREIGN KEY ("collected_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ───────────── Hand-written additions (not expressible in schema.prisma) ─────────────

-- Human-facing order numbers. Read with nextval('order_number_seq').
CREATE SEQUENCE "order_number_seq" START WITH 1001;

-- One primary address per customer, ignoring deleted addresses.
CREATE UNIQUE INDEX "addresses_one_primary_per_user"
  ON "addresses" ("user_id") WHERE "is_primary" AND "deleted_at" IS NULL;

-- At most one accepted offer per order leg: the database settles the race
-- when two drivers accept at the same moment.
CREATE UNIQUE INDEX "dispatch_offers_one_accepted_per_leg"
  ON "dispatch_offers" ("order_id", "leg") WHERE "status" = 'ACCEPTED';

-- Money and quantity sanity checks.
ALTER TABLE "catalog_items"
  ADD CONSTRAINT "catalog_items_price_positive" CHECK ("price_paise" > 0),
  ADD CONSTRAINT "catalog_items_offer_below_price"
    CHECK ("offer_price_paise" IS NULL OR ("offer_price_paise" > 0 AND "offer_price_paise" < "price_paise"));

ALTER TABLE "order_items"
  ADD CONSTRAINT "order_items_quantity_positive" CHECK ("quantity" > 0),
  ADD CONSTRAINT "order_items_amounts_non_negative" CHECK ("unit_price_paise" >= 0 AND "line_total_paise" >= 0);

ALTER TABLE "orders"
  ADD CONSTRAINT "orders_amounts_non_negative"
    CHECK ("subtotal_paise" >= 0 AND "discount_paise" >= 0 AND "delivery_fee_paise" >= 0
           AND "total_paise" >= 0 AND "paid_paise" >= 0);

ALTER TABLE "payments"
  ADD CONSTRAINT "payments_amount_positive" CHECK ("amount_paise" > 0);

ALTER TABLE "promotions"
  ADD CONSTRAINT "promotions_value_valid"
    CHECK (("discount_type" = 'PERCENT' AND "discount_value" BETWEEN 1 AND 100)
        OR ("discount_type" = 'FLAT' AND "discount_value" > 0)),
  ADD CONSTRAINT "promotions_window_valid" CHECK ("valid_to" > "valid_from");

-- Settings is a single row.
ALTER TABLE "business_settings" ADD CONSTRAINT "business_settings_single_row" CHECK ("id" = 1);
INSERT INTO "business_settings" ("id", "updated_at") VALUES (1, now());

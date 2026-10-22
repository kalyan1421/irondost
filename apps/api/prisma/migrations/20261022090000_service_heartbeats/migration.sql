-- One row per service, rewritten on a timer so the database never looks idle.
CREATE TABLE "service_heartbeats" (
    "service" TEXT NOT NULL,
    "beats" INTEGER NOT NULL DEFAULT 0,
    "last_beat_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "service_heartbeats_pkey" PRIMARY KEY ("service")
);

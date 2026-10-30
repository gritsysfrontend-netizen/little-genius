-- Parent accounts, consent, progress, idempotency, and the job outbox.
-- job_outbox.payload is operational JSON for a closed job set, not a lesson document.

CREATE TABLE "parent_accounts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "auth_provider_sub" TEXT NOT NULL,
    "consent_status" TEXT NOT NULL DEFAULT 'none',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMP(3),
    "sessions_revoked_at" TIMESTAMP(3),

    CONSTRAINT "parent_accounts_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "parent_accounts_auth_provider_sub_key" ON "parent_accounts"("auth_provider_sub");

CREATE TABLE "child_profiles" (
    "id" UUID NOT NULL,
    "parent_account_id" UUID NOT NULL,
    "nickname" TEXT NOT NULL,
    "avatar_id" TEXT NOT NULL,
    "age_band" TEXT NOT NULL,
    "preferred_locale" TEXT NOT NULL,
    "bilingual_mode" BOOLEAN NOT NULL,
    "revision" INTEGER NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "child_profiles_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "child_profiles_parent_account_id_idx" ON "child_profiles"("parent_account_id");

CREATE TABLE "learning_events" (
    "event_id" UUID NOT NULL,
    "profile_id" UUID NOT NULL,
    "content_id" TEXT NOT NULL,
    "content_version" INTEGER NOT NULL,
    "event_type" TEXT NOT NULL,
    "duration_bucket" TEXT,
    "occurred_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "learning_events_pkey" PRIMARY KEY ("event_id")
);

CREATE INDEX "learning_events_profile_id_idx" ON "learning_events"("profile_id");

CREATE TABLE "progress_summaries" (
    "profile_id" UUID NOT NULL,
    "category_id" TEXT NOT NULL,
    "started_count" INTEGER NOT NULL DEFAULT 0,
    "completed_count" INTEGER NOT NULL DEFAULT 0,
    "last_activity_at" TIMESTAMP(3),

    CONSTRAINT "progress_summaries_pkey" PRIMARY KEY ("profile_id","category_id")
);

CREATE TABLE "consent_records" (
    "record_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "parent_account_id" UUID NOT NULL,
    "purpose" TEXT NOT NULL,
    "notice_version" TEXT NOT NULL,
    "decision" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consent_records_pkey" PRIMARY KEY ("record_id")
);

CREATE INDEX "consent_records_parent_account_id_idx" ON "consent_records"("parent_account_id");

CREATE TABLE "idempotency_keys" (
    "parent_account_id" UUID NOT NULL,
    "key" UUID NOT NULL,
    "request_sha256" TEXT NOT NULL,
    "status_code" INTEGER NOT NULL,
    "response_body" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("parent_account_id","key")
);

CREATE TABLE "job_outbox" (
    "job_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "parent_account_id" UUID NOT NULL,
    "job_type" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "available_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "result" JSONB,
    "finished_at" TIMESTAMP(3),

    CONSTRAINT "job_outbox_pkey" PRIMARY KEY ("job_id")
);

CREATE INDEX "job_outbox_status_available_at_idx" ON "job_outbox"("status", "available_at");

ALTER TABLE "child_profiles" ADD CONSTRAINT "child_profiles_parent_account_id_fkey" FOREIGN KEY ("parent_account_id") REFERENCES "parent_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "learning_events" ADD CONSTRAINT "learning_events_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "child_profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "progress_summaries" ADD CONSTRAINT "progress_summaries_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "child_profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "consent_records" ADD CONSTRAINT "consent_records_parent_account_id_fkey" FOREIGN KEY ("parent_account_id") REFERENCES "parent_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "idempotency_keys" ADD CONSTRAINT "idempotency_keys_parent_account_id_fkey" FOREIGN KEY ("parent_account_id") REFERENCES "parent_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "job_outbox" ADD CONSTRAINT "job_outbox_parent_account_id_fkey" FOREIGN KEY ("parent_account_id") REFERENCES "parent_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "child_profiles" ADD CONSTRAINT "child_profiles_age_band_check" CHECK ("age_band" IN ('1-2', '2-3', '3-4', '4-5'));
ALTER TABLE "child_profiles" ADD CONSTRAINT "child_profiles_locale_check" CHECK ("preferred_locale" IN ('en', 'hi', 'ta'));
ALTER TABLE "child_profiles" ADD CONSTRAINT "child_profiles_avatar_check" CHECK ("avatar_id" IN ('star', 'sun', 'leaf', 'moon', 'bird', 'fish'));
ALTER TABLE "learning_events" ADD CONSTRAINT "learning_events_type_check" CHECK ("event_type" IN ('started', 'completed'));
ALTER TABLE "learning_events" ADD CONSTRAINT "learning_events_bucket_check" CHECK ("duration_bucket" IS NULL OR "duration_bucket" IN ('lt_1m', 'm1_to_5', 'gt_5m'));
ALTER TABLE "consent_records" ADD CONSTRAINT "consent_records_decision_check" CHECK ("decision" IN ('granted', 'denied'));
ALTER TABLE "job_outbox" ADD CONSTRAINT "job_outbox_type_check" CHECK ("job_type" IN ('export_account', 'delete_account', 'process_asset'));
ALTER TABLE "job_outbox" ADD CONSTRAINT "job_outbox_status_check" CHECK ("status" IN ('pending', 'running', 'completed', 'failed'));

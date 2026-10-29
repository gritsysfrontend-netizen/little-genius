-- Staff drafts, uploaded asset bytes, and the content audit log.
-- Published lesson rows stay on content_versions.

CREATE TABLE "media_asset_blobs" (
    "asset_id" TEXT NOT NULL,
    "content_type" TEXT NOT NULL,
    "bytes" BYTEA NOT NULL,

    CONSTRAINT "media_asset_blobs_pkey" PRIMARY KEY ("asset_id")
);

CREATE TABLE "content_drafts" (
    "id" TEXT NOT NULL,
    "content_id" TEXT NOT NULL,
    "author_sub" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "education_status" TEXT NOT NULL DEFAULT 'pending',
    "education_reviewer_sub" TEXT,
    "rights_status" TEXT NOT NULL DEFAULT 'pending',
    "rights_reviewer_sub" TEXT,
    "state" TEXT NOT NULL DEFAULT 'open',
    "published_version" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "content_drafts_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "draft_locale_reviews" (
    "draft_id" TEXT NOT NULL,
    "locale" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "reviewer_sub" TEXT,

    CONSTRAINT "draft_locale_reviews_pkey" PRIMARY KEY ("draft_id","locale")
);

CREATE TABLE "content_audit_events" (
    "id" TEXT NOT NULL,
    "at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actor_sub" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "content_id" TEXT,
    "draft_id" TEXT,
    "detail" JSONB NOT NULL,

    CONSTRAINT "content_audit_events_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "content_audit_events_at_idx" ON "content_audit_events"("at");

ALTER TABLE "media_asset_blobs" ADD CONSTRAINT "media_asset_blobs_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "media_assets"("asset_id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "draft_locale_reviews" ADD CONSTRAINT "draft_locale_reviews_draft_id_fkey" FOREIGN KEY ("draft_id") REFERENCES "content_drafts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "content_drafts"
  ADD CONSTRAINT "content_drafts_payload_object"
  CHECK (jsonb_typeof("payload") = 'object');

ALTER TABLE "content_drafts"
  ADD CONSTRAINT "content_drafts_education_status"
  CHECK ("education_status" IN ('pending', 'approved', 'rejected'));

ALTER TABLE "content_drafts"
  ADD CONSTRAINT "content_drafts_rights_status"
  CHECK ("rights_status" IN ('pending', 'approved', 'rejected'));

ALTER TABLE "content_drafts"
  ADD CONSTRAINT "content_drafts_state"
  CHECK ("state" IN ('open', 'published'));

ALTER TABLE "draft_locale_reviews"
  ADD CONSTRAINT "draft_locale_reviews_locale"
  CHECK ("locale" IN ('en', 'hi', 'ta'));

ALTER TABLE "draft_locale_reviews"
  ADD CONSTRAINT "draft_locale_reviews_status"
  CHECK ("status" IN ('pending', 'approved', 'rejected'));

ALTER TABLE "content_audit_events"
  ADD CONSTRAINT "content_audit_events_detail_object"
  CHECK (jsonb_typeof("detail") = 'object');

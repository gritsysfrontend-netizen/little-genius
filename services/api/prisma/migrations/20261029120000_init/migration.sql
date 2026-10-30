-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "content_versions" (
    "content_id" TEXT NOT NULL,
    "content_version" INTEGER NOT NULL,
    "schema_version" TEXT NOT NULL,
    "category_id" TEXT NOT NULL,
    "age_min_months" INTEGER NOT NULL,
    "age_max_months" INTEGER NOT NULL,
    "interaction_type" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "payload_sha256" TEXT NOT NULL,

    CONSTRAINT "content_versions_pkey" PRIMARY KEY ("content_id","content_version")
);

-- CreateTable
CREATE TABLE "content_localizations" (
    "content_id" TEXT NOT NULL,
    "content_version" INTEGER NOT NULL,
    "locale" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "instruction" TEXT NOT NULL,
    "feedback_correct" TEXT NOT NULL,
    "review_status" TEXT NOT NULL,

    CONSTRAINT "content_localizations_pkey" PRIMARY KEY ("content_id","content_version","locale")
);

-- CreateTable
CREATE TABLE "media_assets" (
    "asset_id" TEXT NOT NULL,
    "media_type" TEXT NOT NULL,
    "locale" TEXT,
    "object_key" TEXT NOT NULL,
    "sha256" TEXT NOT NULL,
    "byte_size" INTEGER NOT NULL,
    "rights_status" TEXT NOT NULL,

    CONSTRAINT "media_assets_pkey" PRIMARY KEY ("asset_id")
);

-- CreateTable
CREATE TABLE "content_asset_refs" (
    "content_id" TEXT NOT NULL,
    "content_version" INTEGER NOT NULL,
    "asset_id" TEXT NOT NULL,

    CONSTRAINT "content_asset_refs_pkey" PRIMARY KEY ("content_id","content_version","asset_id")
);

-- CreateTable
CREATE TABLE "content_packs" (
    "pack_id" TEXT NOT NULL,
    "pack_version" INTEGER NOT NULL,
    "total_bytes" INTEGER NOT NULL,
    "checksum_sha256" TEXT NOT NULL,
    "min_app_version" TEXT NOT NULL,
    "status" TEXT NOT NULL,

    CONSTRAINT "content_packs_pkey" PRIMARY KEY ("pack_id","pack_version")
);

-- CreateTable
CREATE TABLE "content_pack_items" (
    "pack_id" TEXT NOT NULL,
    "pack_version" INTEGER NOT NULL,
    "content_id" TEXT NOT NULL,
    "content_version" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,

    CONSTRAINT "content_pack_items_pkey" PRIMARY KEY ("pack_id","pack_version","position")
);

-- AddForeignKey
ALTER TABLE "content_localizations" ADD CONSTRAINT "content_localizations_content_id_content_version_fkey" FOREIGN KEY ("content_id", "content_version") REFERENCES "content_versions"("content_id", "content_version") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_asset_refs" ADD CONSTRAINT "content_asset_refs_content_id_content_version_fkey" FOREIGN KEY ("content_id", "content_version") REFERENCES "content_versions"("content_id", "content_version") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_asset_refs" ADD CONSTRAINT "content_asset_refs_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "media_assets"("asset_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_pack_items" ADD CONSTRAINT "content_pack_items_pack_id_pack_version_fkey" FOREIGN KEY ("pack_id", "pack_version") REFERENCES "content_packs"("pack_id", "pack_version") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_pack_items" ADD CONSTRAINT "content_pack_items_content_id_content_version_fkey" FOREIGN KEY ("content_id", "content_version") REFERENCES "content_versions"("content_id", "content_version") ON DELETE RESTRICT ON UPDATE CASCADE;


ALTER TABLE "content_versions"
  ADD CONSTRAINT "content_versions_payload_object"
  CHECK (jsonb_typeof("payload") = 'object');

ALTER TABLE "content_versions"
  ADD CONSTRAINT "content_versions_status"
  CHECK ("status" IN ('draft', 'published', 'unpublished'));

CREATE OR REPLACE FUNCTION content_versions_immutable()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status = 'published' THEN
    IF NEW.payload IS DISTINCT FROM OLD.payload
       OR NEW.payload_sha256 IS DISTINCT FROM OLD.payload_sha256
       OR NEW.schema_version IS DISTINCT FROM OLD.schema_version
       OR NEW.age_min_months IS DISTINCT FROM OLD.age_min_months
       OR NEW.age_max_months IS DISTINCT FROM OLD.age_max_months
       OR NEW.interaction_type IS DISTINCT FROM OLD.interaction_type
       OR NEW.category_id IS DISTINCT FROM OLD.category_id
       OR NEW.content_id IS DISTINCT FROM OLD.content_id
       OR NEW.content_version IS DISTINCT FROM OLD.content_version
    THEN
      RAISE EXCEPTION 'published content version is immutable';
    END IF;
    IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status <> 'unpublished' THEN
      RAISE EXCEPTION 'published content can only transition to unpublished';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER content_versions_immutable_trg
BEFORE UPDATE ON content_versions
FOR EACH ROW
EXECUTE FUNCTION content_versions_immutable();

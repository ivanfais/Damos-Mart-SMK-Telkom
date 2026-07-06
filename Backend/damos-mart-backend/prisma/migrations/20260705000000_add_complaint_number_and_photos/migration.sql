-- Add complaint_number as nullable first so existing rows can be backfilled.
ALTER TABLE "complaints" ADD COLUMN IF NOT EXISTS "complaint_number" TEXT;

-- Backfill legacy complaints with unique numbers before enforcing NOT NULL.
UPDATE "complaints" AS c
SET "complaint_number" = sub.generated_number
FROM (
  SELECT
    id,
    'DM-' || TO_CHAR("created_at", 'DDMMYY') || '-' || LPAD(
      ROW_NUMBER() OVER (
        PARTITION BY DATE("created_at")
        ORDER BY "created_at", id
      )::text,
      4,
      '0'
    ) AS generated_number
  FROM "complaints"
  WHERE "complaint_number" IS NULL
) AS sub
WHERE c.id = sub.id;

-- Safety net: any remaining NULL rows get a guaranteed-unique legacy value.
UPDATE "complaints"
SET "complaint_number" = 'DM-LEGACY-' || "id"
WHERE "complaint_number" IS NULL;

ALTER TABLE "complaints" ALTER COLUMN "complaint_number" SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "complaints_complaint_number_key" ON "complaints"("complaint_number");

CREATE TABLE IF NOT EXISTS "complaint_photos" (
    "id" TEXT NOT NULL,
    "complaint_id" TEXT NOT NULL,
    "photo_url" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "complaint_photos_pkey" PRIMARY KEY ("id")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'complaint_photos_complaint_id_fkey'
  ) THEN
    ALTER TABLE "complaint_photos"
      ADD CONSTRAINT "complaint_photos_complaint_id_fkey"
      FOREIGN KEY ("complaint_id") REFERENCES "complaints"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

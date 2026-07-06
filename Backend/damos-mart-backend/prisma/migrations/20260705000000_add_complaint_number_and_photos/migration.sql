-- AlterTable
ALTER TABLE "complaints" ADD COLUMN "complaint_number" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "complaints_complaint_number_key" ON "complaints"("complaint_number");

-- CreateTable
CREATE TABLE "complaint_photos" (
    "id" TEXT NOT NULL,
    "complaint_id" TEXT NOT NULL,
    "photo_url" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "complaint_photos_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "complaint_photos" ADD CONSTRAINT "complaint_photos_complaint_id_fkey" FOREIGN KEY ("complaint_id") REFERENCES "complaints"("id") ON DELETE CASCADE ON UPDATE CASCADE;

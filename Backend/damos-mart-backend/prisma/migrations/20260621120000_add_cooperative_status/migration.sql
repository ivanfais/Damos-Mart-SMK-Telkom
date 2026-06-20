-- CreateEnum
CREATE TYPE "CooperativeCondition" AS ENUM ('SEPI', 'NORMAL', 'RAMAI');

-- CreateTable
CREATE TABLE "cooperative_status" (
    "id" TEXT NOT NULL,
    "current_condition" "CooperativeCondition" NOT NULL DEFAULT 'NORMAL',
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cooperative_status_pkey" PRIMARY KEY ("id")
);

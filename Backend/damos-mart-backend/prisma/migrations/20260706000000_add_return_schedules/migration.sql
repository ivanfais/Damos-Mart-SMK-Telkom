-- CreateEnum
CREATE TYPE "ReturnTimeSlot" AS ENUM ('BREAK_FIRST', 'BREAK_SECOND', 'SCHOOL_END');

-- CreateTable
CREATE TABLE "return_schedules" (
    "id" TEXT NOT NULL,
    "complaint_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "return_date" TIMESTAMP(3) NOT NULL,
    "time_slot" "ReturnTimeSlot" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "return_schedules_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "return_schedules" ADD CONSTRAINT "return_schedules_complaint_id_fkey" FOREIGN KEY ("complaint_id") REFERENCES "complaints"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "return_schedules" ADD CONSTRAINT "return_schedules_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

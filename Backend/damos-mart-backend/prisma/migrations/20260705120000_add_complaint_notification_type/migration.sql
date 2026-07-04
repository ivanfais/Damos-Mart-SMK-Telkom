-- Add COMPLAINT to notification types for complaint status updates.
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'COMPLAINT';

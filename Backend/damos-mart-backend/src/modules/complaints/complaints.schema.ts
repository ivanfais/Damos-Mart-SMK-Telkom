import { z } from 'zod';

const categoryEnum = z.enum(['PRODUCT', 'SERVICE', 'ORDER', 'QUEUE', 'OTHER']);
const statusEnum = z.enum(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED']);
const priorityEnum = z.enum(['LOW', 'MEDIUM', 'HIGH']);

export const createComplaintSchema = z.object({
  body: z.object({
    subject: z.string().min(3, 'Subjek komplain minimal 3 karakter'),
    description: z.string().min(5, 'Deskripsi komplain minimal 5 karakter'),
    category: categoryEnum.optional().default('OTHER'),
    orderId: z.string().uuid('orderId tidak valid').optional().nullable(),
  }),
});

// Admin can also log a complaint on behalf of a walk-in student (userId optional).
export const adminCreateComplaintSchema = z.object({
  body: z.object({
    subject: z.string().min(3, 'Subjek komplain minimal 3 karakter'),
    description: z.string().min(5, 'Deskripsi komplain minimal 5 karakter'),
    category: categoryEnum.optional().default('OTHER'),
    priority: priorityEnum.optional().default('MEDIUM'),
    userId: z.string().uuid('userId tidak valid').optional().nullable(),
    orderId: z.string().uuid('orderId tidak valid').optional().nullable(),
  }),
});

export const updateComplaintStatusSchema = z.object({
  body: z.object({
    status: statusEnum.optional(),
    priority: priorityEnum.optional(),
  }),
});

export const respondComplaintSchema = z.object({
  body: z.object({
    adminResponse: z.string().min(1, 'Balasan tidak boleh kosong'),
    status: statusEnum.optional(),
  }),
});

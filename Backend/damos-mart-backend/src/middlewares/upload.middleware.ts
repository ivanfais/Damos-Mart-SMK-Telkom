import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { env } from '../config/env';
import { AppError } from './error.middleware';

/**
 * Helper to construct disk storage with dynamic subdirectory routing.
 */
const getStorage = (subfolder: string) => {
  return multer.diskStorage({
    destination: (_req, _file, cb) => {
      const dest = path.join(env.UPLOAD_DIR, subfolder);
      if (!fs.existsSync(dest)) {
        fs.mkdirSync(dest, { recursive: true });
      }
      cb(null, dest);
    },
    filename: (_req, file, cb) => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
      const ext = path.extname(file.originalname);
      cb(null, `${subfolder}-${uniqueSuffix}${ext}`);
    },
  });
};

/**
 * Filter to allow only specific image formats.
 */
const fileFilter = (_req: any, file: any, cb: any) => {
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
  const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];

  const ext = path.extname(file.originalname).toLowerCase();
  const isValidExt = allowedExtensions.includes(ext);
  const isValidMime = allowedMimeTypes.includes(file.mimetype);

  if (isValidExt && isValidMime) {
    return cb(null, true);
  }
  
  cb(
    new AppError(
      400,
      'VALIDATION_ERROR',
      `File format not allowed. Only JPEG, PNG, and WEBP images under ${env.MAX_FILE_SIZE / (1024 * 1024)}MB are accepted.`
    )
  );
};

export const uploadAvatar = multer({
  storage: getStorage('avatars'),
  limits: { fileSize: env.MAX_FILE_SIZE },
  fileFilter,
});

export const uploadProduct = multer({
  storage: getStorage('products'),
  limits: { fileSize: env.MAX_FILE_SIZE },
  fileFilter,
});

export const uploadReview = multer({
  storage: getStorage('reviews'),
  limits: { fileSize: env.MAX_FILE_SIZE },
  fileFilter,
});

export const uploadCategory = multer({
  storage: getStorage('categories'),
  limits: { fileSize: env.MAX_FILE_SIZE },
  fileFilter,
});

export const uploadCooperative = multer({
  storage: getStorage('cooperative'),
  limits: { fileSize: env.MAX_FILE_SIZE },
  fileFilter,
});



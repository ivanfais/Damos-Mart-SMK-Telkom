"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadCooperative = exports.uploadCategory = exports.uploadReview = exports.uploadProduct = exports.uploadAvatar = void 0;
const multer_1 = __importDefault(require("multer"));
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const env_1 = require("../config/env");
const error_middleware_1 = require("./error.middleware");
/**
 * Helper to construct disk storage with dynamic subdirectory routing.
 */
const getStorage = (subfolder) => {
    return multer_1.default.diskStorage({
        destination: (_req, _file, cb) => {
            const dest = path_1.default.join(env_1.env.UPLOAD_DIR, subfolder);
            if (!fs_1.default.existsSync(dest)) {
                fs_1.default.mkdirSync(dest, { recursive: true });
            }
            cb(null, dest);
        },
        filename: (_req, file, cb) => {
            const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
            const ext = path_1.default.extname(file.originalname);
            cb(null, `${subfolder}-${uniqueSuffix}${ext}`);
        },
    });
};
/**
 * Filter to allow only specific image formats.
 */
const fileFilter = (_req, file, cb) => {
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
    const ext = path_1.default.extname(file.originalname).toLowerCase();
    const isValidExt = allowedExtensions.includes(ext);
    const isValidMime = allowedMimeTypes.includes(file.mimetype);
    if (isValidExt && isValidMime) {
        return cb(null, true);
    }
    cb(new error_middleware_1.AppError(400, 'VALIDATION_ERROR', `File format not allowed. Only JPEG, PNG, and WEBP images under ${env_1.env.MAX_FILE_SIZE / (1024 * 1024)}MB are accepted.`));
};
exports.uploadAvatar = (0, multer_1.default)({
    storage: getStorage('avatars'),
    limits: { fileSize: env_1.env.MAX_FILE_SIZE },
    fileFilter,
});
exports.uploadProduct = (0, multer_1.default)({
    storage: getStorage('products'),
    limits: { fileSize: env_1.env.MAX_FILE_SIZE },
    fileFilter,
});
exports.uploadReview = (0, multer_1.default)({
    storage: getStorage('reviews'),
    limits: { fileSize: env_1.env.MAX_FILE_SIZE },
    fileFilter,
});
exports.uploadCategory = (0, multer_1.default)({
    storage: getStorage('categories'),
    limits: { fileSize: env_1.env.MAX_FILE_SIZE },
    fileFilter,
});
exports.uploadCooperative = (0, multer_1.default)({
    storage: getStorage('cooperative'),
    limits: { fileSize: env_1.env.MAX_FILE_SIZE },
    fileFilter,
});

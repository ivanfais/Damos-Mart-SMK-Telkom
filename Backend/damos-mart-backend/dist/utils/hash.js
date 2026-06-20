"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.hashPassword = hashPassword;
exports.comparePassword = comparePassword;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
/**
 * Hashes a plaintext password.
 * @param password Plain text password
 * @returns Hashed password string
 */
async function hashPassword(password) {
    const salt = await bcryptjs_1.default.genSalt(10);
    return bcryptjs_1.default.hash(password, salt);
}
/**
 * Compares plaintext password with its hash.
 * @param password Plain text password
 * @param hash Brypt hashed password
 * @returns boolean
 */
async function comparePassword(password, hash) {
    return bcryptjs_1.default.compare(password, hash);
}

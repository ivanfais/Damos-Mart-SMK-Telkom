import bcrypt from 'bcryptjs';

/**
 * Hashes a plaintext password.
 * @param password Plain text password
 * @returns Hashed password string
 */
export async function hashPassword(password: string): Promise<string> {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
}

/**
 * Compares plaintext password with its hash.
 * @param password Plain text password
 * @param hash Brypt hashed password
 * @returns boolean
 */
export async function comparePassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

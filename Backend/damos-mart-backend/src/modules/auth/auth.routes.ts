import { Router, RequestHandler } from 'express';
import { AuthController } from './auth.controller';
import { validateRequest } from '../../middlewares/validate.middleware';
import {
  registerSchema,
  loginSchema,
  ssoLoginSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  validateResetTokenSchema,
} from './auth.schema';

const router = Router();
const controller = new AuthController();

// Binding controller context helper
const bind = (method: keyof AuthController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

router.post('/register', validateRequest(registerSchema), bind('register'));
router.post('/login', validateRequest(loginSchema), bind('login'));
router.post('/login/sso', validateRequest(ssoLoginSchema), bind('loginSso'));
router.post('/forgot-password', validateRequest(forgotPasswordSchema), bind('forgotPassword'));
router.get(
  '/reset-password/validate',
  validateRequest(validateResetTokenSchema),
  bind('validateResetToken'),
);
router.post('/reset-password', validateRequest(resetPasswordSchema), bind('resetPassword'));
router.post('/refresh', validateRequest(refreshTokenSchema), bind('refresh'));
router.post('/logout', validateRequest(refreshTokenSchema), bind('logout'));

export default router;

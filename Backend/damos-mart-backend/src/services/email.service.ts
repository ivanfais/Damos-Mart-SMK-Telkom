import nodemailer from 'nodemailer';
import { env } from '../config/env';

function createTransport() {
  if (!env.SMTP_HOST || !env.SMTP_USER || !env.SMTP_PASS) {
    return null;
  }

  return nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: env.SMTP_PORT,
    secure: env.SMTP_SECURE,
    auth: {
      user: env.SMTP_USER,
      pass: env.SMTP_PASS,
    },
  });
}

export async function sendPasswordResetEmail(input: {
  to: string;
  fullName: string;
  resetUrl: string;
}) {
  const subject = 'Reset Password Damos Mart';
  const text = [
    `Halo ${input.fullName},`,
    '',
    'Kami menerima permintaan reset password untuk akun Damos Mart Anda.',
    'Klik link berikut untuk membuat password baru (berlaku 1 jam):',
    input.resetUrl,
    '',
    'Jika Anda tidak meminta reset password, abaikan email ini.',
    '',
    'Salam,',
    'Tim Damos Mart',
  ].join('\n');

  const html = `
    <p>Halo <strong>${input.fullName}</strong>,</p>
    <p>Kami menerima permintaan reset password untuk akun Damos Mart Anda.</p>
    <p>
      <a href="${input.resetUrl}" style="display:inline-block;padding:12px 20px;background:#1B8C2E;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:700;">
        Reset Password
      </a>
    </p>
    <p>Atau salin link berikut ke browser Anda:</p>
    <p><a href="${input.resetUrl}">${input.resetUrl}</a></p>
    <p>Link berlaku selama <strong>1 jam</strong>.</p>
    <p>Jika Anda tidak meminta reset password, abaikan email ini.</p>
    <p>Salam,<br/>Tim Damos Mart</p>
  `;

  const transport = createTransport();
  if (!transport) {
    console.log('[Email] SMTP not configured. Password reset link:');
    console.log(`  To: ${input.to}`);
    console.log(`  ${input.resetUrl}`);
    return;
  }

  await transport.sendMail({
    from: env.SMTP_FROM,
    to: input.to,
    subject,
    text,
    html,
  });
}

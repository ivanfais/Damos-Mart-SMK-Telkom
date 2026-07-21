import nodemailer from 'nodemailer';
import { env } from '../config/env';

export function isSmtpConfigured(): boolean {
  return Boolean(env.SMTP_HOST && env.SMTP_USER && env.SMTP_PASS);
}

function createTransport() {
  if (!isSmtpConfigured()) {
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

export async function sendPasswordResetCodeEmail(params: {
  to: string;
  fullName: string;
  code: string;
}): Promise<void> {
  const { to, fullName, code } = params;
  const subject = 'Kode Verifikasi Reset Password - Damos Mart';
  const text = [
    `Halo ${fullName},`,
    '',
    `Kode verifikasi reset password kamu adalah: ${code}`,
    '',
    'Kode berlaku 15 menit. Jangan bagikan kode ini kepada siapa pun.',
    '',
    'Jika kamu tidak meminta reset password, abaikan email ini.',
    '',
    '— Damos Mart SMK Telkom Jakarta',
  ].join('\n');

  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.5; color: #1a1a1a;">
      <p>Halo <strong>${fullName}</strong>,</p>
      <p>Kode verifikasi reset password kamu adalah:</p>
      <p style="font-size: 28px; font-weight: 700; letter-spacing: 6px; color: #1B8C2E;">${code}</p>
      <p>Kode berlaku <strong>15 menit</strong>. Jangan bagikan kode ini kepada siapa pun.</p>
      <p style="color: #6b7280; font-size: 13px;">Jika kamu tidak meminta reset password, abaikan email ini.</p>
      <p>— Damos Mart SMK Telkom Jakarta</p>
    </div>
  `;

  const transport = createTransport();
  if (!transport) {
    console.warn(`[mailer] SMTP not configured. Password reset code for ${to}: ${code}`);
    return;
  }

  await transport.sendMail({
    from: env.SMTP_FROM,
    to,
    subject,
    text,
    html,
  });
}

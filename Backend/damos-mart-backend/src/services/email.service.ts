import dns from 'node:dns';
import nodemailer from 'nodemailer';
import { env } from '../config/env';

// Railway often fails on Gmail IPv6 (ENETUNREACH). Prefer IPv4.
dns.setDefaultResultOrder('ipv4first');

const SMTP_CONNECTION_TIMEOUT_MS = 10_000;
const SMTP_SOCKET_TIMEOUT_MS = 15_000;
const SMTP_SEND_TIMEOUT_MS = 18_000;

export function isResendConfigured(): boolean {
  return Boolean(env.RESEND_API_KEY);
}

export function isSmtpConfigured(): boolean {
  return Boolean(env.SMTP_HOST && env.SMTP_USER && env.SMTP_PASS);
}

export function isEmailConfigured(): boolean {
  return isResendConfigured() || isSmtpConfigured();
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
    connectionTimeout: SMTP_CONNECTION_TIMEOUT_MS,
    greetingTimeout: SMTP_CONNECTION_TIMEOUT_MS,
    socketTimeout: SMTP_SOCKET_TIMEOUT_MS,
  } as nodemailer.TransportOptions);
}

async function sendViaResend(options: {
  to: string;
  subject: string;
  text: string;
  html: string;
}): Promise<void> {
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: env.SMTP_FROM,
      to: [options.to],
      subject: options.subject,
      text: options.text,
      html: options.html,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`RESEND_FAILED ${response.status}: ${body}`);
  }
}

async function sendViaSmtp(options: {
  to: string;
  subject: string;
  text: string;
  html: string;
}): Promise<void> {
  const transport = createTransport();
  if (!transport) {
    throw new Error('SMTP_NOT_CONFIGURED');
  }

  await Promise.race([
    transport.sendMail({
      from: env.SMTP_FROM,
      to: options.to,
      subject: options.subject,
      text: options.text,
      html: options.html,
    }),
    new Promise<never>((_, reject) => {
      setTimeout(
        () => reject(new Error('SMTP_SEND_TIMEOUT')),
        SMTP_SEND_TIMEOUT_MS,
      );
    }),
  ]);
}

async function sendMail(options: {
  to: string;
  subject: string;
  text: string;
  html: string;
}): Promise<void> {
  // Prefer Resend (HTTP) — works on Railway. SMTP to Gmail is often blocked.
  if (isResendConfigured()) {
    await sendViaResend(options);
    return;
  }

  if (!isSmtpConfigured()) {
    throw new Error('EMAIL_NOT_CONFIGURED');
  }

  await sendViaSmtp(options);
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

  if (!isEmailConfigured()) {
    console.log('[Email] Email provider not configured. Password reset link:');
    console.log(`  To: ${input.to}`);
    console.log(`  ${input.resetUrl}`);
    return;
  }

  await sendMail({ to: input.to, subject, text, html });
}

export async function sendPasswordResetCodeEmail(input: {
  to: string;
  fullName: string;
  code: string;
}) {
  const subject = 'Kode Verifikasi Reset Password - Damos Mart';
  const text = [
    `Halo ${input.fullName},`,
    '',
    `Kode verifikasi reset password kamu adalah: ${input.code}`,
    '',
    'Kode berlaku 15 menit. Jangan bagikan kode ini kepada siapa pun.',
    '',
    'Jika kamu tidak meminta reset password, abaikan email ini.',
    '',
    '— Damos Mart SMK Telkom Jakarta',
  ].join('\n');

  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.5; color: #1a1a1a;">
      <p>Halo <strong>${input.fullName}</strong>,</p>
      <p>Kode verifikasi reset password kamu adalah:</p>
      <p style="font-size: 28px; font-weight: 700; letter-spacing: 6px; color: #1B8C2E;">${input.code}</p>
      <p>Kode berlaku <strong>15 menit</strong>. Jangan bagikan kode ini kepada siapa pun.</p>
      <p style="color: #6b7280; font-size: 13px;">Jika kamu tidak meminta reset password, abaikan email ini.</p>
      <p>— Damos Mart SMK Telkom Jakarta</p>
    </div>
  `;

  if (!isEmailConfigured()) {
    console.warn(`[Email] Email provider not configured. Password reset code for ${input.to}: ${input.code}`);
    return;
  }

  await sendMail({ to: input.to, subject, text, html });
}

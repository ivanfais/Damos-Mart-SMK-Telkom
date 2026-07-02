import nodemailer from 'nodemailer';
import { env } from '../config/env';

type SendMailOptions = {
  to: string;
  subject: string;
  text: string;
  html: string;
};

let transporter: nodemailer.Transporter | null = null;

function getTransporter(): nodemailer.Transporter | null {
  if (!env.SMTP_HOST || !env.SMTP_USER || !env.SMTP_PASS) {
    return null;
  }

  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: env.SMTP_HOST,
      port: env.SMTP_PORT,
      secure: env.SMTP_SECURE,
      auth: {
        user: env.SMTP_USER,
        pass: env.SMTP_PASS,
      },
    });
  }

  return transporter;
}

export async function sendMail(options: SendMailOptions): Promise<void> {
  const mailer = getTransporter();

  if (!mailer) {
    return;
  }

  await mailer.sendMail({
    from: env.SMTP_FROM,
    to: options.to,
    subject: options.subject,
    text: options.text,
    html: options.html,
  });
}

export function isSmtpConfigured(): boolean {
  return !!(env.SMTP_HOST && env.SMTP_USER && env.SMTP_PASS);
}

export function logDevEmailFallback(to: string, subject: string, resetUrl?: string): void {
  console.log('\n============================================================');
  console.log('📧 [DEV MODE] SMTP belum dikonfigurasi — email TIDAK dikirim ke inbox');
  console.log('   (Salin link di bawah, buka di tab browser Flutter yang sama)');
  console.log('============================================================');
  console.log(`Kepada   : ${to}`);
  console.log(`Subjek   : ${subject}`);
  if (resetUrl) {
    console.log('Link reset password:');
    console.log(resetUrl);
  }
  console.log('============================================================\n');
}

export async function sendPasswordResetEmail(email: string, resetUrl: string): Promise<void> {
  const subject = 'Reset Password - Damos Mart';
  const text = [
    'Halo,',
    '',
    'Kami menerima permintaan reset password untuk akun Damos Mart Anda.',
    'Klik link berikut untuk mengatur password baru:',
    resetUrl,
    '',
    'Link berlaku selama 1 jam. Jika Anda tidak meminta reset password, abaikan email ini.',
    '',
    'Salam,',
    'Tim Damos Mart SMK Telkom Jakarta',
  ].join('\n');

  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #1a1a1a;">
      <h2 style="color: #008816;">Reset Password Damos Mart</h2>
      <p>Halo,</p>
      <p>Kami menerima permintaan reset password untuk akun Damos Mart Anda.</p>
      <p>
        <a href="${resetUrl}" style="display:inline-block;padding:12px 20px;background:#008816;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:bold;">
          Reset Password
        </a>
      </p>
      <p>Atau salin link berikut ke browser Anda:</p>
      <p><a href="${resetUrl}">${resetUrl}</a></p>
      <p>Link berlaku selama <strong>1 jam</strong>.</p>
      <p style="color:#757575;font-size:13px;">Jika Anda tidak meminta reset password, abaikan email ini.</p>
      <hr style="border:none;border-top:1px solid #e0e0e0;margin:24px 0;" />
      <p style="color:#757575;font-size:12px;">Damos Mart — SMK Telkom Jakarta</p>
    </div>
  `;

  if (!isSmtpConfigured()) {
    logDevEmailFallback(email, subject, resetUrl);
    return;
  }

  await sendMail({ to: email, subject, text, html });
  console.log(`📧 [SMTP] Email reset password terkirim ke ${email}`);
}

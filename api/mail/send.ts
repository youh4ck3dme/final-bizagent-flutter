import { VercelRequest, VercelResponse } from '@vercel/node';
import * as admin from 'firebase-admin';
import sgMail from '@sendgrid/mail';

// Initialize Firebase Admin
if (!admin.apps.length) {
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
    ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
    : undefined;

  admin.initializeApp({
    credential: serviceAccount ? admin.credential.cert(serviceAccount) : admin.credential.applicationDefault(),
    projectId: process.env.FIREBASE_PROJECT_ID || 'bizagent-live-2026'
  });
}

const db = admin.firestore();

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // 1. Security Check
  const appCheckToken = req.headers['x-firebase-appcheck'] as string;
  if (!appCheckToken) return res.status(401).json({ error: 'Missing App Check' });

  try {
    await admin.appCheck().verifyToken(appCheckToken);
  } catch (err) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // 2. Extract Data
  const { to, subject, html, text, invoiceId, userId } = req.body;

  if (!to || !subject || (!html && !text)) {
    return res.status(400).json({ error: 'Missing email parameters' });
  }

  const apiKey = process.env.SENDGRID_API_KEY;
  const from = process.env.MAIL_FROM || 'BizAgent <no-reply@bizagent.sk>';

  if (!apiKey) return res.status(500).json({ error: 'SendGrid not configured' });
  sgMail.setApiKey(apiKey);

  const msg = { to, from, subject, text, html };

  try {
    await sgMail.send(msg);

    // 3. Log to Firestore
    await db.collection('mail_logs').add({
      userId: userId || 'anonymous',
      invoiceId: invoiceId || null,
      to,
      subject,
      status: 'sent',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      gateway: 'vercel'
    });

    return res.status(200).json({ success: true });
  } catch (error: any) {
    console.error('SendGrid Error:', error);

    // Log failure
    await db.collection('mail_logs').add({
      userId: userId || 'anonymous',
      to,
      status: 'failed',
      error: error.message,
      sentAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return res.status(500).json({ error: 'Failed to send email' });
  }
}

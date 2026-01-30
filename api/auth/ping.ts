import { VercelRequest, VercelResponse } from '@vercel/node';
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
    ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
    : undefined;

  admin.initializeApp({
    credential: serviceAccount ? admin.credential.cert(serviceAccount) : admin.credential.applicationDefault(),
    projectId: process.env.FIREBASE_PROJECT_ID || 'bizagent-live-2026'
  });
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const appCheckToken = req.headers['x-firebase-appcheck'] as string;

  if (!appCheckToken) {
    return res.status(401).json({ ok: false, message: 'Missing App Check token' });
  }

  try {
    const result = await admin.appCheck().verifyToken(appCheckToken);
    return res.status(200).json({
      ok: true,
      message: 'App Check Verified',
      appId: result.appId,
      enforced: true,
      gateway: 'vercel'
    });
  } catch (err: any) {
    return res.status(401).json({ ok: false, message: err.message });
  }
}

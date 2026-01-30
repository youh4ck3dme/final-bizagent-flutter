import { VercelRequest, VercelResponse } from '@vercel/node';
import * as admin from 'firebase-admin';

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

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Security: Verify App Check Token
  const appCheckToken = req.headers['x-firebase-appcheck'] as string;
  if (!appCheckToken) {
    return res.status(401).json({ error: 'Missing App Check token' });
  }

  try {
    await admin.appCheck().verifyToken(appCheckToken);
  } catch (err) {
    console.error('App Check verification failed:', err);
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const ico = req.query.ico as string;

  if (!ico) {
    return res.status(400).json({ error: 'Missing IČO parameter' });
  }

  // Pad ICO to 8 digits if numeric
  const paddedIco = ico.padStart(8, '0');

  // Get API key from environment
  const apiKey = process.env.ICOATLAS_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'Server configuration error' });
  }

  try {
    const response = await fetch(`https://icoatlas.sk/api/company/${paddedIco}`, {
      headers: {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json'
      }
    });

    if (response.status === 404) {
      return res.status(404).json({ error: 'Company not found' });
    }

    if (response.status === 401 || response.status === 403) {
      return res.status(500).json({ error: 'Authentication error' });
    }

    if (!response.ok) {
      return res.status(response.status).json({ error: 'External API error' });
    }

    const data = await response.json();

    // Transform to match our expected format
    const result = {
      name: data.name || '',
      ico: data.ico || ico,
      dic: data.dic || '',
      icDph: data.ic_dph || '',
      address: data.address || '',
      source: 'icoatlas.sk',
      fetchedAt: new Date().toISOString()
    };

    return res.status(200).json(result);
  } catch (error) {
    console.error('IcoAtlas proxy error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

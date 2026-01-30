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

  const { country, vat } = req.query;
  const countryCode = (country as string).toUpperCase();
  const vatNumber = (vat as string).trim();

  const soapEnvelope = `<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
 xmlns:tns="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
  <soap:Body>
    <tns:checkVat>
      <tns:countryCode>${countryCode}</tns:countryCode>
      <tns:vatNumber>${vatNumber}</tns:vatNumber>
    </tns:checkVat>
  </soap:Body>
</soap:Envelope>`;

  try {
    const response = await fetch('https://ec.europa.eu/taxation_customs/vies/services/checkVatService', {
      method: 'POST',
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': 'checkVat',
      },
      body: soapEnvelope,
    });

    if (!response.ok) {
      return res.status(502).json({ error: 'VIES service unreachable' });
    }

    const xmlText = await response.text();

    // Simple Regex Parsing for SOAP response to avoid huge dependencies in serverless
    const getValue = (tag: string) => {
      const regex = new RegExp(`<${tag}[^>]*>([^<]*)<\/${tag}>`, 'i');
      const match = xmlText.match(regex);
      return match ? match[1] : '';
    };

    const isValid = getValue('valid').toLowerCase() === 'true';
    const name = getValue('name');
    const address = getValue('address').replace(/\\n/g, ', ');
    const requestDate = getValue('requestDate');

    return res.status(200).json({
      valid: isValid,
      name: name || (isValid ? 'Valid VAT Entity' : ''),
      address: address || '',
      countryCode,
      vatNumber,
      requestDate,
      source: 'VIES',
      fetchedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('VIES lookup error:', error);
    return res.status(500).json({ error: 'Internal server error while calling VIES' });
  }
}

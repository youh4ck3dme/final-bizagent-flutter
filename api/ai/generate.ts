import { VercelRequest, VercelResponse } from '@vercel/node';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';

// Initialize Firebase Admin if not already initialized
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
  // 1. Basic Method Check
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // 2. Security: Verify App Check Token
  const appCheckToken = req.headers['x-firebase-appcheck'] as string;
  if (!appCheckToken) {
    return res.status(401).json({ error: 'Missing App Check token' });
  }

  try {
    await admin.appCheck().verifyToken(appCheckToken);
  } catch (err) {
    console.error('App Check verification failed:', err);
    return res.status(401).json({ error: 'Unauthorized: Invalid App Check token' });
  }

  // 3. Extract Parameters
  const { prompt, type, tone, context, model: requestedModel } = req.body;

  // 4. Handle Different AI Request Types
  try {
    // A. Generic Text Generation (Gemini)
    if (!type || type === 'generic') {
      const apiKey = process.env.GEMINI_API_KEY;
      if (!apiKey) return res.status(500).json({ error: 'GEMINI_API_KEY not configured' });

      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-pro" });
      const systemInstruction = "Si BizAgent AI - inteligentný asistent pre slovenských podnikateľov. Odpovedaj stručne, vecne a v slovenčine.";

      const result = await model.generateContent(`${systemInstruction}\n\nUser: ${prompt}`);
      const response = await result.response;
      return res.status(200).json({ text: response.text() });
    }

    // B. Email Generation (OpenAI)
    if (type === 'email') {
      const apiKey = process.env.OPENAI_API_KEY;
      if (!apiKey) return res.status(500).json({ error: 'OPENAI_API_KEY not configured' });

      const systemInstruction = "Si profesionálny biznis asistent pre slovenských podnikateľov. Tvojou úlohou je písať e-maily v slovenčine.";
      const fullPrompt = `Napíš ${type} e-mail v ${tone || 'profesionálnom'} tóne. Kontext: ${context || prompt}`;

      const resp = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: requestedModel || "gpt-4o",
          messages: [
            { role: "system", content: systemInstruction },
            { role: "user", content: fullPrompt }
          ]
        })
      });

      if (!resp.ok) throw new Error(`OpenAI error: ${resp.status}`);
      const json = await resp.json();
      return res.status(200).json({ text: json.choices?.[0]?.message?.content || "" });
    }

    return res.status(400).json({ error: 'Unsupported request type' });

  } catch (error: any) {
    console.error('AI Proxy Error:', error);
    return res.status(500).json({ error: error.message || 'Internal server error' });
  }
}

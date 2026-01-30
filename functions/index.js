const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();

const geminiApiKey = defineString("GEMINI_API_KEY");
const openaiApiKey = defineString("OPENAI_API_KEY");
const openaiModelPrimary = defineString("OPENAI_MODEL_PRIMARY");
const openaiModelFallback = defineString("OPENAI_MODEL_FALLBACK");
const icoAtlasApiKey = defineString("ICOATLAS_API_KEY");
const sendgridApiKey = defineString("SENDGRID_API_KEY");
const mailFrom = defineString("MAIL_FROM");

/**
 * Generuje AI odpoveď cez OpenAI (server-side), s fallback modelom.
 * Používa sa pre chatbota a iné prompt-based AI funkcie z Flutter Web.
 */
// --- 1. Chatbot (Gemini Fallback) ---
exports.generateAiText = onCall(
  {
    cors: true,
    enforceAppCheck: true, // Reject missing/invalid App Check tokens
    secrets: [geminiApiKey],
  },
  async (request) => {
    const { prompt } = request.data || {};

    if (!prompt || typeof prompt !== "string") {
      throw new HttpsError("invalid-argument", 'Chýba parameter "prompt".');
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Server nie je správne nakonfigurovaný (chýba GEMINI_API_KEY)."
      );
    }

    // Initialize Gemini
    const { GoogleGenerativeAI } = require("@google/generative-ai");
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });

    const systemInstruction =
      "Si BizAgent AI - inteligentný asistent pre slovenských podnikateľov. Odpovedaj stručne, vecne a v slovenčine.";

    // Construct prompt with system instruction
    const fullPrompt = `${systemInstruction}\n\nUser: ${prompt}`;

    try {
      const result = await model.generateContent(fullPrompt);
      const response = await result.response;
      const text = response.text();
      return { text: text };
    } catch (error) {
      console.error("Gemini Error:", error);
      throw new HttpsError("internal", "Chyba pri generovaní AI odpovede: " + error.message);
    }
  }
);

/**
 * Generuje profesionálny e-mail na základe kontextu.
 */
exports.generateEmail = onCall({
  cors: true,
  enforceAppCheck: true,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Funkcia musí byť volaná prihláseným používateľom.');
  }

  const { type, tone, context } = request.data;
  if (!context) {
    throw new HttpsError('invalid-argument', 'Chýba parameter "context".');
  }

  const apiKey = openaiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba OPENAI_API_KEY).');
  }

  const systemInstruction = "Si profesionálny biznis asistent pre slovenských podnikateľov. Tvojou úlohou je písať e-maily, ktoré sú gramaticky správne, slušné a vecne presné podľa zadaného kontextu. Používaj spisovnú slovenčinu a profesionálne formátovanie.";
  const prompt = `Napíš ${type} e-mail v ${tone} tóne. Kontext: ${context}`;

  try {
    const resp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: "gpt-4o",
        temperature: 0.7,
        messages: [
          { role: "system", content: systemInstruction },
          { role: "user", content: prompt }
        ]
      })
    });

    if (!resp.ok) {
       const text = await resp.text();
       console.error("OpenAI Email Error:", resp.status, text);
       throw new HttpsError("internal", `OpenAI API Error: ${resp.status}`);
    }

    const json = await resp.json();
    const content = json.choices?.[0]?.message?.content || "";

    return { text: content };

  } catch (error) {
    console.error("OpenAI Email Exception:", error);
    throw new HttpsError('internal', 'Chyba pri generovaní e-mailu: ' + error.message);
  }
});

/**
 * Parsuje text z bločku pomocou AI pre presnejšie dáta.
 */
exports.analyzeReceipt = onCall({
  cors: true,
  enforceAppCheck: true,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Prístup odmietnutý.');
  }

  const { text } = request.data;
  if (!text) {
    throw new HttpsError('invalid-argument', 'Chýba text na analýzu.');
  }

  const apiKey = openaiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba OPENAI_API_KEY).');
  }

  const systemInstruction = `Si expert na analýzu slovenských pokladničných dokladov.
      Z extrahovaného textu vytiahni údaje do čistého JSONu v tejto štruktúre:
      {
        "vendor_name": "Názov obchodu",
        "ico": "XXXXXXXX (ak existuje)",
        "date": "YYYY-MM-DD",
        "total": 0.0,
        "currency": "EUR",
        "address": {
          "street": "Ulica",
          "street_number": "Číslo",
          "psc": "PSČ",
          "city": "Mesto"
        },
        "confidence": 0.9 (odhad istoty)
      }
      Ak údaj nevieš nájsť, nechaj ho null. Odpovedaj iba čistým JSONom bez markdownu.`;

  try {
     const resp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: "gpt-4o",
        temperature: 0.1, // Low temp for data extraction
        messages: [
          { role: "system", content: systemInstruction },
          { role: "user", content: `Analyzuj text:\n\n${text}` }
        ],
        response_format: { type: "json_object" } // Enforce JSON mode
      })
    });

    if (!resp.ok) {
       const errText = await resp.text();
       console.error("OpenAI Receipt Error:", resp.status, errText);
       throw new HttpsError("internal", `OpenAI API Error: ${resp.status}`);
    }

    const json = await resp.json();
    const content = json.choices?.[0]?.message?.content || "{}";

    return JSON.parse(content);
  } catch (error) {
    console.error("OpenAI Receipt Exception:", error);
    throw new HttpsError('internal', 'Chyba pri analýze dokladu: ' + error.message);
  }
});

/**
 * Hľadá firmu podľa IČO.
 * Používa IcoAtlas.sk API s proxy cez server-side kľúčom.
 */
exports.lookupCompany = onCall({
  cors: true,
  enforceAppCheck: true,
}, async (request) => {
  // Allow unauthenticated for onboarding flow (strictly rate limited in prod)
  // For now, allow it to speed up "Magic Setup"

  const { ico } = request.data;
  if (!ico) {
    throw new HttpsError('invalid-argument', 'Chýba IČO.');
  }

  // Pad ICO to 8 digits if numeric
  const paddedIco = ico.padStart(8, '0');

  const apiKey = icoAtlasApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba API kľúč).');
  }

  // 1. Real API Call (IcoAtlas.sk)
  try {
    const response = await fetch(`https://icoatlas.sk/api/company/${paddedIco}`, {
      headers: {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json'
      }
    });

    if (response.status === 404) {
      throw new HttpsError('not-found', 'Firma sa nenašla.');
    }

    if (response.status === 401 || response.status === 403) {
      console.error("Missing or invalid API key for IcoAtlas");
      throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba alebo neplatný API kľúč pre IcoAtlas).');
    }

    if (!response.ok) {
       console.error("IcoAtlas API Error:", response.status, await response.text());
       return null;
    }

    const data = await response.json();
    if (!data) return null;

    // Map to our simplified format
    return {
      name: data.name || '',
      ico: data.ico || ico,
      dic: data.dic || '',
      icDph: data.ic_dph || '',
      address: data.address || '',
      source: 'icoatlas.sk',
      fetchedAt: new Date().toISOString()
    };

  } catch (error) {
    console.error("Lookup Error:", error);
    throw new HttpsError('internal', 'Chyba pri hľadaní firmy.');
  }
});
/**
 * Security Ping to verify App Check enforcement.
 */
exports.securityPing = onCall({
  enforceAppCheck: true,
}, async (request) => {
  return {
    ok: true,
    appId: request.app?.appId ?? null,
    enforced: true,
    timestamp: new Date().toISOString(),
  };
});
/**
 * Send invoice email via SendGrid.
 */
exports.sendInvoiceEmail = onCall({
  enforceAppCheck: true,
  secrets: [sendgridApiKey],
}, async (request) => {
  const { to, subject, html } = request.data || {};
  if (!to || !subject || !html) {
    throw new HttpsError("invalid-argument", "Missing required fields (to, subject, html).");
  }

  const apiKey = sendgridApiKey.value();
  if (!apiKey) {
    throw new HttpsError("failed-precondition", "Missing SENDGRID_API_KEY.");
  }
  sgMail.setApiKey(apiKey);

  const from = mailFrom.value() || "BizAgent <no-reply@bizagent.sk>";
  const msg = { to, from, subject, html };

  try {
    const [resp] = await sgMail.send(msg);

    await admin.firestore().collection("mail_logs").add({
      to,
      subject,
      status: "sent",
      sendgridStatus: resp.statusCode,
      at: admin.firestore.FieldValue.serverTimestamp(),
      uid: request.auth?.uid ?? null,
    });

    return { ok: true };
  } catch (error) {
    console.error("SendGrid Error:", error);

    await admin.firestore().collection("mail_logs").add({
      to,
      subject,
      status: "failed",
      error: error.message,
      at: admin.firestore.FieldValue.serverTimestamp(),
      uid: request.auth?.uid ?? null,
    });

    throw new HttpsError("internal", "Email sending failed: " + error.message);
  }
});

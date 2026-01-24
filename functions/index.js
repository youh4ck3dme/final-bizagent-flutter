const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineString } = require("firebase-functions/params");

const geminiApiKey = defineString("GEMINI_API_KEY");
const openaiApiKey = defineString("OPENAI_API_KEY");
const openaiModelPrimary = defineString("OPENAI_MODEL_PRIMARY");
const openaiModelFallback = defineString("OPENAI_MODEL_FALLBACK");
const icoAtlasApiKey = defineString("ICOATLAS_API_KEY");

// Model configuration
// UPDEJT: Prejdené na 2.0 flash (stable model)
const MODEL_NAME = "gemini-2.0-flash";

/**
 * Generuje AI odpoveď cez OpenAI (server-side), s fallback modelom.
 * Používa sa pre chatbota a iné prompt-based AI funkcie z Flutter Web.
 */
exports.generateAiText = onCall(
  {
    cors: true, // TODO: Pre produkciu obmedz origin(y)
  },
  async (request) => {
    const { prompt, models } = request.data || {};

    if (!prompt || typeof prompt !== "string") {
      throw new HttpsError("invalid-argument", 'Chýba parameter "prompt".');
    }

    const apiKey = openaiApiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Server nie je správne nakonfigurovaný (chýba OPENAI_API_KEY)."
      );
    }

    const primary = (openaiModelPrimary.value() || "gpt-4o-mini").trim();
    const fallback = (openaiModelFallback.value() || "gpt-4o").trim();
    const requestedModels = Array.isArray(models)
      ? models.filter((m) => typeof m === "string" && m.trim().length > 0)
      : [];

    // Whitelist to avoid arbitrary expensive models from clients.
    const allowed = new Set([primary, fallback, "gpt-4o-mini", "gpt-4o"]);
    const candidates = [
      ...requestedModels.filter((m) => allowed.has(m)),
      primary,
      fallback,
    ].filter((v, i, a) => a.indexOf(v) === i);

    const systemInstruction =
      "Si BizAgent AI - inteligentný asistent pre slovenských podnikateľov. Odpovedaj stručne, vecne a v slovenčine.";

    const callOnce = async (model) => {
      const resp = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model,
          temperature: 0.2,
          messages: [
            { role: "system", content: systemInstruction },
            { role: "user", content: prompt },
          ],
        }),
      });

      const json = await resp.json().catch(() => null);
      if (!resp.ok) {
        const message =
          (json && json.error && json.error.message) ||
          `OpenAI request failed with HTTP ${resp.status}`;
        const err = new Error(message);
        err.status = resp.status;
        throw err;
      }

      const text =
        json?.choices?.[0]?.message?.content ||
        json?.choices?.[0]?.text ||
        "";
      return { text, model };
    };

    let lastError = null;
    for (const model of candidates) {
      try {
        const result = await callOnce(model);
        return { text: result.text, model: result.model };
      } catch (err) {
        lastError = err;

        if (err?.status === 401 || err?.status === 403) {
          throw new HttpsError(
            "permission-denied",
            "Neplatný alebo chýbajúci OpenAI API kľúč."
          );
        }

        if (err?.status === 429) {
          throw new HttpsError(
            "resource-exhausted",
            "Limit dopytov bol prekročený."
          );
        }

        // Try next model.
        continue;
      }
    }

    console.error("OpenAI generateAiText error:", lastError);
    throw new HttpsError("internal", "Chyba pri generovaní AI odpovede.");
  }
);

/**
 * Generuje profesionálny e-mail na základe kontextu.
 */
exports.generateEmail = onCall({ 
  cors: true // TODO: Pre produkciu zmeň na ["https://bizagent-live-2026.web.app"]
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Funkcia musí byť volaná prihláseným používateľom.');
  }

  const { type, tone, context } = request.data;
  if (!context) {
    throw new HttpsError('invalid-argument', 'Chýba parameter "context".');
  }

  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba API kľúč).');
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ 
      model: MODEL_NAME,
      systemInstruction: "Si profesionálny biznis asistent pre slovenských podnikateľov. Tvojou úlohou je písať e-maily, ktoré sú gramaticky správne, slušné a vecne presné podľa zadaného kontextu. Používaj spisovnú slovenčinu a profesionálne formátovanie."
    });

    const prompt = `Napíš ${type} e-mail v ${tone} tóne. Kontext: ${context}`;
    
    const result = await model.generateContent(prompt);
    return { text: result.response.text() };

  } catch (error) {
    console.error("Gemini Email Error:", error);
    if (error.status === 403 || error.message.includes('API key')) {
      throw new HttpsError('permission-denied', 'Neplatný API kľúč pre AI službu.');
    }
    throw new HttpsError('internal', 'Chyba pri generovaní e-mailu: ' + error.message);
  }
});

/**
 * Parsuje text z bločku pomocou AI pre presnejšie dáta.
 */
exports.analyzeReceipt = onCall({ 
  cors: true 
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Prístup odmietnutý.');
  }

  const { text } = request.data;
  if (!text) {
    throw new HttpsError('invalid-argument', 'Chýba text na analýzu.');
  }

  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný.');
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ 
      model: MODEL_NAME,
      systemInstruction: `Si expert na analýzu slovenských pokladničných dokladov. 
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
      Ak údaj nevieš nájsť, nechaj ho null.`
    });

    const result = await model.generateContent(`Analyzuj text:\n\n${text}`);
    const jsonString = result.response.text().replace(/```json|```/g, '').trim();
    
    return JSON.parse(jsonString);
  } catch (error) {
    console.error("Gemini Receipt Error:", error);
    throw new HttpsError('internal', 'Chyba pri analýze dokladu: ' + error.message);
  }
});

/**
 * Hľadá firmu podľa IČO.
 * Používa IcoAtlas.sk API s proxy cez server-side kľúčom.
 */
exports.lookupCompany = onCall({
  cors: true
}, async (request) => {
  // Allow unauthenticated for onboarding flow (strictly rate limited in prod)
  // For now, allow it to speed up "Magic Setup"

  const { ico } = request.data;
  if (!ico) {
    throw new HttpsError('invalid-argument', 'Chýba IČO.');
  }

  // Pad ICO to 8 digits if numeric
  const paddedIco = ico.padStart(8, '0');

  // 1. Try Mock Data (For Demo "Wow" Effect without API Key)
  const MOCK_DB = {
    '36396567': { // Google Slovakia
      name: 'Google Slovakia, s. r. o.',
      ico: '36396567',
      dic: '2020102636',
      icDph: 'SK2020102636',
      address: 'Karadžičova 8/A, Bratislava 821 08'
    },
    '35757442': { // O2 Slovakia
      name: 'O2 Slovakia, s.r.o.',
      ico: '35757442',
      dic: '2020216748',
      icDph: 'SK2020216748',
      address: 'Einsteinova 24, Bratislava 851 01'
    },
    '46113177': { // SkyToll
      name: 'SkyToll, a. s.',
      ico: '46113177',
      dic: '2023247964',
      icDph: 'SK2023247964',
      address: 'Lamačská cesta 3/B, Bratislava 841 04'
    }
  };

  const apiKey = icoAtlasApiKey.value();

  // Ak nemáme kľúč alebo je to známe testovacie IČO, vráť mock
  if (!apiKey || MOCK_DB[ico]) {
    console.log("Using Mock/Fallback for IČO:", ico);
    if (MOCK_DB[ico]) return MOCK_DB[ico];

    // Ak nemáme kľúč a nie je v mocku:
    if (!apiKey) {
       return null;
    }
  }

  // 2. Real API Call (IcoAtlas.sk)
  try {
    const response = await fetch(`https://icoatlas.sk/api/company/${paddedIco}`, {
      headers: {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json'
      }
    });

    if (response.status === 404) {
      console.log("Endpoint mismatch for IČO:", ico);
      return null;
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
      address: data.address || ''
    };

  } catch (error) {
    console.error("Lookup Error:", error);
    throw new HttpsError('internal', 'Chyba pri hľadaní firmy.');
  }
});

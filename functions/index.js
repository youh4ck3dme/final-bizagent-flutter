const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require("firebase-functions/params");

const geminiApiKey = defineSecret("GEMINI_API_KEY");

exports.generateEmail = onCall({ secrets: [geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Funkcia musí byť volaná prihláseným používateľom.');
  }

  const { type, tone, context } = request.data;
  
  if (!context) {
    throw new HttpsError('invalid-argument', 'Chýba parameter "context".');
  }

  const apiKey = geminiApiKey.value();
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({ model: "gemini-pro"});

  const prompt = `
Úloha: Napíš profesionálny firemný e-mail v slovenskom jazyku.

Parametre:
- Typ správy: ${type}
- Tón komunikácie: ${tone}
- Kontext/Detaily: "${context}"

Požiadavky:
- Použij spisovnú slovenčinu.
- Dodržuj štruktúru: Oslovenie, Jadro správy, Záver, Podpis (ako [Meno/Firma]).
- Buď stručný ale zdvorilý.
- Nevymýšľaj si fakty, ktoré nie sú v kontexte.
`;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    return { text: text };
  } catch (error) {
    console.error("Error calling Gemini API:", error);
    throw new HttpsError('internal', 'Chyba pri generovaní obsahu cez AI.');
  }
});

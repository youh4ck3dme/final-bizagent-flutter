
// Mock implementation of BizBot Chat API
// Gemini 2.5 Flash Lite + Context Memory

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { message, context, userId } = req.body;

    // Simulate AI processing delay
    setTimeout(() => {
      let response = "Nerozumiem otázke.";

      if (message.includes("odvody")) {
        response = "Minimálne odvody pre SZČO v roku 2026 sú 344,27 € do Sociálnej poisťovne a 107,24 € do zdravotnej poisťovne.";
      } else if (message.includes("daň")) {
        response = "Daň z príjmu pre SZČO je 15% (ak príjem < 60k €) alebo 19% z rozdielu základu dane.";
      } else {
        response = "Rozumiem, že sa pýtaš na: '" + message + "'. Keďže som v demo režime, skús sa spýtať na odvody alebo dane.";
      }

      res.status(200).json({
        text: response,
        confidence: 0.9,
        citations: []
      });
    }, 1000);

  } catch (error) {
    res.status(500).json({ error: 'BizBot unavailable' });
  }
}

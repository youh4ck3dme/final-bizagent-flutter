
// Mock implementation of Server-side Vision API for Vercel
// Compatible with Gemini 2.5 Flash Lite

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { image } = req.body;

    // In production, this would call Vertex AI / Gemini API
    // const result = await gemini.generateContent([prompt, image]);

    // Mock response
    setTimeout(() => {
      res.status(200).json({
        vendor: "Tesco Stores SR",
        date: "2026-02-04",
        total: 45.80,
        vat: 7.63,
        items: [
          {name: "Chlieb", price: 2.50},
          {name: "Mlieko", price: 1.80},
          {name: "Jablká", price: 3.20}
        ],
        confidence: 0.98
      });
    }, 1500);

  } catch (error) {
    res.status(500).json({ error: 'AI Vision Analysis Failed' });
  }
}

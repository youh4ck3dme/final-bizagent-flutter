/**
 * AI Intelligence Layer — Company Verdict (server-side only).
 * Model: Gemini 2.5 Flash Lite. Canonical prompt, JSON-only, fallback when data quality < 0.4 or model fails.
 * See docs/AI_VERDICT_LAYER.md.
 */

import { GoogleGenerativeAI } from '@google/generative-ai';

/** Output format for company verdict (no hallucinations, business-safe). */
export interface CompanyVerdictOutput {
  headline: string;
  explanation: string;
  confidence: number;
}

/** Fallback when dataQualityScore < 0.4 or model/parse fails. */
export const FALLBACK_VERDICT: CompanyVerdictOutput = {
  headline: 'Údaje sú obmedzené.',
  explanation:
    'Pre podrobnú analýzu sú potrebné ďalšie údaje. Odporúčame overiť údaje v registri.',
  confidence: 0,
};

const DATA_QUALITY_THRESHOLD = 0.4;
const VERDICT_MODEL = 'gemini-2.5-flash-lite';

const SYSTEM_INSTRUCTION = `Si interný modul BizAgent pre stručný posudok firmy. Tvoja jediná úloha je vrátiť JSON s poliami headline, explanation, confidence.

Pravidlá:
- Vychádzaj VÝLUČNE z poskytnutých vstupov (názov firmy, stav, skóre kvality dát). Žiadne externé fakty, žiadne domnienky.
- Nepoužívaj informácie, ktoré nie sú vo vstupe. Žiadne halucinácie.
- Jazyk: slovenčina, profesionálny, neutrálny. Žiadne odporúčania na nákup/predaj, žiadne právne rady.
- headline: jedna krátka veta (max. cca 80 znakov). Napr. "Firma je aktívna." alebo "Údaje sú obmedzené."
- explanation: jedna až dve vety, vysvetlenie na základe status a dataQualityScore. Bez citácií, bez zdrojov.
- confidence: číslo 0.0 až 1.0 podľa toho, ako veľa spoľahlivých vstupov máš. Ak je dataQualityScore nízke, confidence zníž.
- Odpoveď musí byť IBA platný JSON, žiadny úvodný text ani markdown. Formát: {"headline":"...","explanation":"...","confidence":0.0}`;

function buildUserMessage(companyName: string, status: string, dataQualityScore: number): string {
  return `companyName: ${companyName}
status: ${status}
dataQualityScore: ${dataQualityScore}

Vráť jediný JSON objekt s kľúčmi headline, explanation, confidence. Žiadny iný text.`;
}

const RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    headline: { type: 'string', description: 'One short sentence, max ~80 chars' },
    explanation: { type: 'string', description: 'One or two sentences' },
    confidence: { type: 'number', description: '0.0 to 1.0' },
  },
  required: ['headline', 'explanation', 'confidence'],
};

function parseVerdict(text: string): CompanyVerdictOutput | null {
  const trimmed = text.trim();
  const jsonMatch = trimmed.match(/\{[\s\S]*\}/);
  const jsonStr = jsonMatch ? jsonMatch[0] : trimmed;
  try {
    const parsed = JSON.parse(jsonStr) as Record<string, unknown>;
    const headline = typeof parsed.headline === 'string' ? parsed.headline : '';
    const explanation = typeof parsed.explanation === 'string' ? parsed.explanation : '';
    const confidence =
      typeof parsed.confidence === 'number'
        ? Math.max(0, Math.min(1, parsed.confidence))
        : typeof parsed.confidence === 'string'
          ? Math.max(0, Math.min(1, parseFloat(parsed.confidence) || 0))
          : 0;
    if (!headline || !explanation) return null;
    return { headline, explanation, confidence };
  } catch {
    return null;
  }
}

/**
 * Generate company verdict (headline, explanation, confidence).
 * Returns fallback when dataQualityScore < 0.4, model fails, or response is invalid.
 */
export async function generateCompanyVerdict(
  companyName: string,
  status: string,
  dataQualityScore: number,
  apiKey: string
): Promise<CompanyVerdictOutput> {
  if (dataQualityScore < DATA_QUALITY_THRESHOLD) {
    return FALLBACK_VERDICT;
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: VERDICT_MODEL,
      systemInstruction: SYSTEM_INSTRUCTION,
      generationConfig: {
        temperature: 0,
        responseMimeType: 'application/json',
        responseSchema: RESPONSE_SCHEMA,
      } as Record<string, unknown>,
    });

    const userMessage = buildUserMessage(companyName, status, dataQualityScore);
    const result = await model.generateContent(userMessage);
    const response = result.response;
    const text = response.text();
    if (!text) return FALLBACK_VERDICT;

    const verdict = parseVerdict(text);
    if (verdict) {
      if (verdict.confidence < DATA_QUALITY_THRESHOLD) return FALLBACK_VERDICT;
      return verdict;
    }
  } catch {
    // timeout, rate limit, or model error
  }
  return FALLBACK_VERDICT;
}

/**
 * Map verdict output to API contract: riskLevel (LOW | MEDIUM | HIGH), riskHint = explanation.
 */
export function verdictToRiskLevel(confidence: number): 'LOW' | 'MEDIUM' | 'HIGH' {
  if (confidence >= 0.7) return 'LOW';
  if (confidence >= 0.4) return 'MEDIUM';
  return 'HIGH';
}

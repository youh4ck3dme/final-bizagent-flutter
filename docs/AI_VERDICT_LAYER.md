# AI Intelligence Layer — Company Verdict (BizAgent)

**Model:** Gemini 2.5 Flash Lite (server-side only)  
**Purpose:** Deterministic, JSON-only company verdict for Internal API (PRO). No hallucinations; business-safe language.

---

## 1. Input / Output

**Input (only what we have):**
- `companyName` (string)
- `status` (string, e.g. Aktívna, Konkurz, Likvidácia)
- `dataQualityScore` (number 0–1)

**Output (strict schema):**
```json
{
  "headline": "...",
  "explanation": "...",
  "confidence": 0.0
}
```

- **headline:** One short sentence (max ~80 chars), business-safe.
- **explanation:** One or two sentences, no external facts, no speculation.
- **confidence:** 0–1; how confident the model is given the **input only** (no extra data).

**Mapping to API contract (Internal):**
- `aiVerdict.headline` = output.headline
- `aiVerdict.explanation` = output.explanation
- `aiVerdict.confidence` = output.confidence
- `aiVerdict.riskLevel` = derived from confidence: `confidence >= 0.7 → "LOW"`, `0.4 <= confidence < 0.7 → "MEDIUM"`, `confidence < 0.4 → "HIGH"` (or use fallback)
- `aiVerdict.riskHint` = output.explanation (or first sentence, max ~120 chars)

---

## 2. Canonical AI Prompt (validated, deterministic)

**System instruction (fixed):**
```
Si interný modul BizAgent pre stručný posudok firmy. Tvoja jediná úloha je vrátiť JSON s poliami headline, explanation, confidence.

Pravidlá:
- Vychádzaj VÝLUČNE z poskytnutých vstupov (názov firmy, stav, skóre kvality dát). Žiadne externé fakty, žiadne domnienky.
- Nepoužívaj informácie, ktoré nie sú vo vstupe. Žiadne halucinácie.
- Jazyk: slovenčina, profesionálny, neutrálny. Žiadne odporúčania na nákup/ predaj, žiadne právne rady.
- headline: jedna krátka veta (max. cca 80 znakov). Napr. "Firma je aktívna." alebo "Údaje sú obmedzené."
- explanation: jedna až dve vety, vysvetlenie na základe status a dataQualityScore. Bez citácií, bez zdrojov.
- confidence: číslo 0.0 až 1.0 podľa toho, ako veľa spoľahlivých vstupov máš. Ak je dataQualityScore nízke, confidence zníž.
- Odpoveď musí byť IBA platný JSON, žiadny úvodný text ani markdown. Formát: {"headline":"...","explanation":"...","confidence":0.0}
```

**User message (template):**
```
companyName: {{companyName}}
status: {{status}}
dataQualityScore: {{dataQualityScore}}

Vráť jediný JSON objekt s kľúčmi headline, explanation, confidence. Žiadny iný text.
```

**Determinism:**
- Use **temperature: 0** (or 0.1) for generation.
- Same input → same output; no creative variation.
- Keep system + user prompt fixed; no dynamic “be creative” instructions.

---

## 3. JSON-only output (enforcement)

- **Gemini:** Use `responseMimeType: "application/json"` and optionally `responseSchema` so the model returns only valid JSON.
- **Schema for response (optional but recommended):**
```json
{
  "type": "object",
  "properties": {
    "headline": { "type": "string", "maxLength": 120 },
    "explanation": { "type": "string", "maxLength": 400 },
    "confidence": { "type": "number", "minimum": 0, "maximum": 1 }
  },
  "required": ["headline", "explanation", "confidence"]
}
```
- **Post-parse:** If the response is not valid JSON or misses required keys, **do not use it** — return **fallback verdict** (see below).

---

## 4. Fallback verdict (data quality < 0.4 or model fails)

**When to use fallback:**
1. `dataQualityScore < 0.4`, or
2. Model call fails (timeout, error, rate limit), or
3. Response is not valid JSON or missing required fields, or
4. Parsed `confidence` from model is < 0.4 (optional: treat as low confidence and still use fallback for consistency).

**Fallback payload (fixed):**
```json
{
  "headline": "Údaje sú obmedzené.",
  "explanation": "Pre podrobnú analýzu sú potrebné ďalšie údaje. Odporúčame overiť údaje v registri.",
  "confidence": 0.0
}
```

**Mapping to API contract when using fallback:**
- `aiVerdict.riskLevel` = `"HIGH"` (unknown/low confidence → treat as higher risk for display)
- `aiVerdict.riskHint` = fallback explanation
- `_confidence` in metadata = 0.0

**No hallucinations:** Fallback does not invent company-specific facts; it states only that data are limited.

---

## 5. Rules (summary)

| Rule | Implementation |
|------|----------------|
| No hallucinations | Prompt: "Vychádzaj VÝLUČNE z poskytnutých vstupov"; no external APIs in prompt. |
| No external facts | Only companyName, status, dataQualityScore in user message. |
| Business-safe language | Prompt: "profesionálny, neutrálny; žiadne právne rady, žiadne odporúčania nákup/predaj". |
| Deterministic | temperature 0 (or 0.1); fixed system + user template. |
| JSON-only | responseMimeType + responseSchema; on parse failure → fallback. |
| Fallback | Use when dataQualityScore < 0.4 or model/parse fails; fixed fallback object. |

---

## 6. Model and placement

- **Model:** `gemini-2.5-flash-lite` (server-side only; never expose API key to client).
- **Where:** Next.js gateway (e.g. `/api/internal/ico/full` or dedicated `/api/ai/verdict`) or Firebase Functions; same logic, single canonical prompt and fallback.
- **Implementation:** `api/ai/verdict.ts` — `generateCompanyVerdict(companyName, status, dataQualityScore, apiKey)`, `FALLBACK_VERDICT`, `verdictToRiskLevel(confidence)`.

---

## 7. Example (success)

**Input:** companyName = "BizAgent s.r.o.", status = "Aktívna", dataQualityScore = 0.9  

**Output:**
```json
{
  "headline": "Firma je aktívna.",
  "explanation": "Na základe dostupných údajov je firma v stave aktívna. Kvalita vstupných dát je vysoká.",
  "confidence": 0.9
}
```

**Example (fallback — low data quality):**

**Input:** dataQualityScore = 0.3  

**Output (fallback):**
```json
{
  "headline": "Údaje sú obmedzené.",
  "explanation": "Pre podrobnú analýzu sú potrebné ďalšie údaje. Odporúčame overiť údaje v registri.",
  "confidence": 0.0
}
```

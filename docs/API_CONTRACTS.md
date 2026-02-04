# BizAgent — FINAL API Contracts (IČO Lookup)

This document defines the **final** API contracts for the Next.js gateway IČO lookup endpoints: Public (Lead Magnet) and Internal (PRO). All responses include metadata; source of truth for company data is **icoatlas.sk** (see `docs/ARCHITECTURE_FINAL.md`).

---

## 1. Endpoints overview

| Endpoint | Auth | Purpose | Data |
|----------|------|---------|------|
| `GET /api/public/ico/lookup?ico={ico}` | None | Lead magnet, landing pages | Limited fields |
| `GET /api/internal/ico/full?ico={ico}` | Bearer Firebase ID Token | PRO app, full company + AI Verdict | Full data + AI Verdict |

**Common:**
- Query param `ico`: 8-digit IČO (leading zeros optional; normalized to 8 digits).
- All **success** responses include metadata: `_mode`, `_source`, `_confidence`, `_updatedAt`.
- **Response header:** `X-API-Version: 1` (budúci upgrade bez rozbitia klientov).
- Errors return a consistent error shape.

---

## 2. Public API — Lead Magnet

**Request**
```http
GET /api/public/ico/lookup?ico=12345678
Accept: application/json
```

**Response headers**
```http
X-API-Version: 1
```

**Success (200)** — Limited fields for lead gen; no DIČ/IČ DPH, no AI verdict. **Monetization:** `upgrade` (dôvod na platbu) a `riskBadge` (teaser bez vysvetlenia).

**JSON Schema (Public response)**
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["ico", "name", "status", "upgrade", "riskBadge", "_mode", "_source", "_updatedAt"],
  "properties": {
    "ico":       { "type": "string", "description": "8-digit IČO" },
    "name":      { "type": "string", "description": "Company name" },
    "status":    { "type": "string", "description": "e.g. Aktívna, Konkurz" },
    "city":      { "type": "string", "description": "City (no full address)" },
    "riskBadge": { "type": "string", "enum": ["LOW", "MEDIUM", "HIGH"], "description": "Rule-based risk teaser (not AI); not explained — creates curiosity" },
    "upgrade": {
      "type": "object",
      "required": ["required", "reason", "cta"],
      "properties": {
        "required": { "type": "boolean", "description": "Always true for public" },
        "reason":   { "type": "string", "description": "Why user should upgrade" },
        "cta":      { "type": "string", "description": "Call-to-action label" }
      }
    },
    "_mode":     { "type": "string", "enum": ["public"], "description": "API mode" },
    "_source":   { "type": "string", "enum": ["icoatlas", "cache"], "description": "Data origin" },
    "_confidence": { "type": "number", "minimum": 0, "maximum": 1, "description": "Data confidence 0–1" },
    "_updatedAt": { "type": "string", "format": "date-time", "description": "When data was last updated" }
  },
  "additionalProperties": false
}
```

**Example (200)**
```json
{
  "ico": "31333541",
  "name": "BizAgent s.r.o.",
  "status": "Aktívna",
  "city": "Bratislava",
  "riskBadge": "LOW",
  "upgrade": {
    "required": true,
    "reason": "Full risk analysis, ownership and history are available in PRO",
    "cta": "Unlock PRO analysis"
  },
  "_mode": "public",
  "_source": "icoatlas",
  "_confidence": 1,
  "_updatedAt": "2026-01-31T12:00:00.000Z"
}
```

**Public — riskBadge (bez AI):**
- Hodnota `LOW` | `MEDIUM` | `HIGH` pochádza z **pravidiel** (regresné pravidlá, nie AI).
- Nie je vysvetlená — vyvolá otázku „prečo?“ a podporuje konverziu do PRO.

---

## 3. Internal API — PRO (full + AI Verdict)

**Request**
```http
GET /api/internal/ico/full?ico=12345678
Authorization: Bearer <Firebase ID Token>
Accept: application/json
```

**Response headers**
```http
X-API-Version: 1
```

**Success (200)** — Full company data plus AI Verdict. **AI Verdict:** `riskLevel` zjednotený na `LOW` | `MEDIUM` | `HIGH`; `riskHint` = krátka veta (jednoduchšie pre UI aj billing).

**JSON Schema (Internal response)**
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["ico", "name", "status", "_mode", "_source", "_updatedAt"],
  "properties": {
    "ico":             { "type": "string" },
    "icoNorm":         { "type": "string", "description": "8-digit normalized IČO" },
    "name":            { "type": "string" },
    "status":          { "type": "string" },
    "street":          { "type": "string" },
    "city":            { "type": "string" },
    "postalCode":      { "type": "string" },
    "fullAddress":     { "type": "string", "description": "street, postalCode, city joined" },
    "dic":             { "type": ["string", "null"] },
    "icDph":           { "type": ["string", "null"] },
    "registrationDate": { "type": ["string", "null"], "description": "e.g. Založené" },
    "aiVerdict": {
      "type": ["object", "null"],
      "properties": {
        "headline":    { "type": "string" },
        "explanation": { "type": "string" },
        "riskLevel":   { "type": "string", "enum": ["LOW", "MEDIUM", "HIGH"], "description": "Unified for UI and billing" },
        "riskHint":    { "type": "string", "description": "Short sentence (one line)" },
        "confidence":  { "type": "number", "minimum": 0, "maximum": 1 }
      }
    },
    "_mode":     { "type": "string", "enum": ["internal"] },
    "_source":   { "type": "string", "enum": ["icoatlas", "cache"] },
    "_confidence": { "type": "number", "minimum": 0, "maximum": 1 },
    "_updatedAt": { "type": "string", "format": "date-time" }
  },
  "additionalProperties": false
}
```

**Internal — aiVerdict.riskLevel a riskHint:**
- **riskLevel:** iba `LOW` | `MEDIUM` | `HIGH` (zjednotené, rovnaká škála ako public `riskBadge`).
- **riskHint:** krátka veta (jedna čiarka OK), napr. „Žiadne rizikové signály.“ alebo „Pozor na oneskorené podklady.“

**Example (200)**
```json
{
  "ico": "31333541",
  "icoNorm": "31333541",
  "name": "BizAgent s.r.o.",
  "status": "Aktívna",
  "street": "Example 1",
  "city": "Bratislava",
  "postalCode": "81101",
  "fullAddress": "Example 1, 81101 Bratislava",
  "dic": "2021234567",
  "icDph": "SK2021234567",
  "registrationDate": "2010-05-15",
  "aiVerdict": {
    "headline": "Firma v dobrom stave.",
    "explanation": "Žiadne rizikové signály.",
    "riskLevel": "LOW",
    "riskHint": "Žiadne rizikové signály.",
    "confidence": 0.92
  },
  "_mode": "internal",
  "_source": "icoatlas",
  "_confidence": 0.92,
  "_updatedAt": "2026-01-31T12:00:00.000Z"
}
```

---

## 4. Metadata and headers (all responses)

**Response header**
| Header | Value | Description |
|--------|-------|-------------|
| `X-API-Version` | `1` | API verzia; budúci upgrade bez rozbitia klientov. |

**Body metadata**
| Field | Type | Description |
|-------|------|-------------|
| `_mode` | string | `"public"` or `"internal"` — which API was used. |
| `_source` | string | `"icoatlas"` — fresh from icoatlas.sk; `"cache"` — gateway/Firestore cache. |
| `_confidence` | number | 0–1; for internal, can mirror `aiVerdict.confidence` or overall data confidence. |
| `_updatedAt` | string | ISO 8601; when the returned data was last updated (fetch or cache write). |

**Public-only fields (monetization)**
| Field | Type | Description |
|-------|------|-------------|
| `riskBadge` | string | `LOW` \| `MEDIUM` \| `HIGH` — rule-based teaser (not AI), not explained. |
| `upgrade` | object | `required`, `reason`, `cta` — dôvod na platbu, podpora konverzie do PRO. |

---

## 5. Cache strategy

- **Source of truth:** Company factual data comes only from **icoatlas.sk** (`GET https://icoatlas.sk/api/company/{ico}`). Gateway and clients may cache it.
- **Public API:** Gateway may cache responses keyed by `ico` with a short TTL (e.g. 1–24 h) to reduce load on icoatlas.sk and respect rate limits. On cache hit, `_source` = `"cache"`, `_updatedAt` = cache write time.
- **Internal API:** Same upstream; gateway (or PRO client) may use a longer-lived cache (e.g. Firestore `companies/{ico}` with 24 h TTL). AI Verdict can be:
  - Computed on each request (no verdict cache), or
  - Cached by `ico` with TTL (e.g. 24 h) and `_source` / `_updatedAt` reflecting when verdict was generated.
- **Invalidation:** Cache is invalidated by TTL only (no explicit purge). Stale-while-revalidate: optional background refresh after TTL; serve stale until new data is available.
- **Rate limits:** If icoatlas.sk returns 429, gateway responds with `429` and `retryAfter` (see Errors). Public API may apply its own per-IP or per-key limits.

---

## 6. Error & fallback behavior

**Common error response shape**
```json
{
  "error": "Human-readable message",
  "code": "MACHINE_CODE",
  "status": 400,
  "retryAfter": null
}
```

- `error`: Short message for clients/logs.
- `code`: Stable code for handling (e.g. `MISSING_ICO`, `UNAUTHORIZED`, `NOT_FOUND`, `RATE_LIMITED`, `UPSTREAM_ERROR`).
- `status`: HTTP status code.
- `retryAfter`: Optional; seconds or ISO date after which to retry (e.g. on 429).

**Public API**

| Scenario | HTTP | Code | Behavior |
|----------|------|------|----------|
| Missing `ico` | 400 | `MISSING_ICO` | Return error; no fallback. |
| Invalid `ico` (non-8-digit) | 400 | `INVALID_ICO` | Return error. |
| Company not found (icoatlas 404) | 404 | `NOT_FOUND` | Return error; no fallback. |
| Rate limited (icoatlas 429) | 429 | `RATE_LIMITED` | Return error; set `retryAfter` if upstream provides it. |
| Upstream/network error | 502 | `UPSTREAM_ERROR` | No fallback; optional: serve from cache if fresh enough (then `_source`: `cache`). |
| Gateway error | 500 | `INTERNAL_ERROR` | No fallback. |

**Internal API**

| Scenario | HTTP | Code | Behavior |
|----------|------|------|----------|
| Missing/invalid `Authorization` | 401 | `UNAUTHORIZED` | Return error. |
| Invalid/expired Firebase token | 401 | `UNAUTHORIZED` | Return error. |
| Missing `ico` | 400 | `MISSING_ICO` | Return error. |
| Invalid `ico` | 400 | `INVALID_ICO` | Return error. |
| Company not found | 404 | `NOT_FOUND` | Return error. |
| Rate limited | 429 | `RATE_LIMITED` | Return error; `retryAfter` if available. |
| Upstream error | 502 | `UPSTREAM_ERROR` | **Fallback:** If gateway has cache for this `ico`, return cached full data; `aiVerdict` may be omitted or stale; `_source`: `cache`, `_confidence` may be lower. If no cache, return 502. |
| AI Verdict failure | 200 | — | **Fallback:** Return full company data from icoatlas (or cache); set `aiVerdict: null` and `_confidence` from data only. Do not fail the whole request. |
| Gateway error | 500 | `INTERNAL_ERROR` | No fallback. |

**Summary**
- Public: no auth; errors are terminal except optional 502→cache.
- Internal: auth required; on upstream failure, fallback to cached full data when available; on AI failure, return data without verdict.

---

## 7. Versioning and contract stability

- **Response header:** `X-API-Version: 1` — všetky odpovede (success aj error) obsahujú túto hlavičku; budúci upgrade bez rozbitia klientov.
- Base path je stabilný: `/api/public/ico/lookup`, `/api/internal/ico/full`.
- Nové voliteľné polia môžu byť pridané; existujúce required polia sa neodstraňujú.
- Breaking zmeny budú verzované (napr. `X-API-Version: 2` alebo path `/v2/...`) pri zavedení.

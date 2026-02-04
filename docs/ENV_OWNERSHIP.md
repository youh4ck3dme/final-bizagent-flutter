# Environment Variables — Ownership & Templates

This document defines which environment variables belong to each layer. **No secrets in frontend** except Firebase public keys. **IcoAtlas API key only server-side.**

---

## 1. Flutter client

**Scope:** Build-time / runtime config for the Flutter app (PRO client).  
**No secrets:** Only public/safe values (e.g. App Check site key, optional gateway URL).

| Variable | Required | Description |
|----------|----------|--------------|
| `GATEWAY_BASE_URL` | No | Base URL of Next.js gateway (e.g. `https://bizagent.sk`). Passed via `--dart-define`. If unset, autocomplete/VIES are disabled; company lookup still uses icoatlas.sk directly. |
| `APP_CHECK_WEB_SITE_KEY` | No (web) | reCAPTCHA Enterprise site key for Firebase App Check on web. Public key. |

**Removed / legacy (do not use):**
- `ICO_MODE` — removed; company data always from icoatlas.sk.
- `GEMINI_API_KEY` — **never in client**; AI calls go through gateway only.

**Firebase (public):** Firebase API keys, project ID, auth domain are in `lib/firebase_options.dart` (or Google Services files). Not in `.env.flutter`.

**Template:** `.env.flutter.example` → copy to `.env.flutter` and fill; use via `--dart-define-from-file=.env.flutter` or equivalent.

---

## 2. Next.js gateway (Vercel / `api/` and `app/api/`)

**Scope:** Server-side only. Used by Vercel serverless (`api/*.ts`) and App Router (`app/api/*`).

| Variable | Required | Description |
|----------|----------|--------------|
| `FIREBASE_PROJECT_ID` | Yes | Firebase project ID (e.g. `bizagent-live-2026`). |
| `FIREBASE_SERVICE_ACCOUNT` | Yes | Firebase Admin SDK service account JSON **string** (single line). Used for App Check verification and Admin SDK. |
| `ICOATLAS_API_KEY` | Yes (company/lead magnet) | IcoAtlas API key. Server-side only; used when gateway proxies company lookup or lead magnet. |
| `GEMINI_API_KEY` | Yes (AI generate) | Gemini API key for `/api/ai/generate` (generic AI). |
| `OPENAI_API_KEY` | No (optional AI) | OpenAI API key for email generation and other OpenAI-backed routes. |
| `SENDGRID_API_KEY` | Yes (mail) | SendGrid API key for `/api/mail/send`. |
| `MAIL_FROM` | No | From address for emails (default e.g. `BizAgent <no-reply@bizagent.sk>`). |
| `ICOATLAS_LOOKUP_PATH` | No | Override for IcoAtlas company API base (default `https://icoatlas.sk/api/company`). |

**Removed / legacy (do not use):**
- `ICO_MODE` — removed.
- `ICOATLAS_FUNCTION_URL` — removed; gateway calls icoatlas.sk directly.
- `SERVICE_ACCOUNT_KEY` — use `FIREBASE_SERVICE_ACCOUNT` (full JSON), not a separate key file path.

**Template:** `.env.gateway.example` → copy to `.env` (or Vercel env vars) for local/dev and production.

---

## 3. Firebase Functions

**Scope:** Firebase Functions (v2). Use `defineString` / params or Secret Manager; local dev can use `.env` in `functions/`.

| Variable | Required | Description |
|----------|----------|--------------|
| `GEMINI_API_KEY` | Yes (AI) | Gemini API key for AI callable. Prefer Secret Manager. |
| `OPENAI_API_KEY` | Yes (if using OpenAI) | OpenAI API key for callables. |
| `OPENAI_MODEL_PRIMARY` | No | Primary model (e.g. `gpt-4o`). |
| `OPENAI_MODEL_FALLBACK` | No | Fallback model (e.g. `gpt-4o-mini`). |
| `ICOATLAS_API_KEY` | Yes (batch/company) | IcoAtlas API key for batch refresh and company lookup callables. |
| `SENDGRID_API_KEY` | Yes (mail) | SendGrid API key for email callables. |
| `MAIL_FROM` | No | From address for emails. |
| `RECAPTCHA_API_KEY` | Yes (if using recaptcha) | reCAPTCHA Enterprise API key (server key). Use Secret Manager. |

**Removed / legacy (do not use):**
- `ICO_MODE`, `ICOATLAS_FUNCTION_URL`, `SERVICE_ACCOUNT_KEY` — same as gateway.

**Template:** `.env.functions.example` → copy to `functions/.env` for local emulator; production: set via Firebase config or Secret Manager.

---

## 4. Summary

| Layer | Secrets allowed? | IcoAtlas key | Gemini key |
|-------|------------------|--------------|------------|
| Flutter | No (only Firebase public + App Check site key) | No | No (AI via gateway) |
| Next.js gateway | Yes (all server-side) | Yes | Yes |
| Firebase Functions | Yes (params/secrets) | Yes | Yes |

**Final env templates (copy and fill):**
- **Flutter:** `.env.flutter.example` → copy to `.env.flutter`; use `--dart-define-from-file=.env.flutter` or pass each key via `--dart-define`.
- **Gateway:** `.env.gateway.example` → copy to `.env` (Vercel dev) or set in Vercel dashboard.
- **Functions:** `.env.functions.example` → copy to `functions/.env` for emulator; production use Firebase config or Secret Manager.

**Removed / legacy (do not use anywhere):** `ICO_MODE`, `ICOATLAS_FUNCTION_URL`, `SERVICE_ACCOUNT_KEY`.

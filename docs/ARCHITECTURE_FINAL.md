# BizAgent — Final Architecture (Normalized)

This document is the **authoritative** description of BizAgent’s system boundaries and responsibilities. No duplication of responsibility; one source of truth per concern.

---

## 1. Architecture layers

| Layer | Responsibility | No other layer does this |
|-------|----------------|---------------------------|
| **IcoAtlas (icoatlas.sk)** | Single source of truth for **company data** (IČO lookup, company info). | Company factual data comes only from here. |
| **Firebase** | Auth, users, subscriptions, Firestore snapshots (user data, invoices, expenses, cache). | Identity, entitlements, and user-owned data. |
| **Next.js gateway (e.g. bizagent.sk)** | AI Verdict generation, public lead magnet API, monetization logic. | AI and business/gateway features. |
| **Flutter app (PRO client)** | UI, orchestration, caching (e.g. Firestore cache for company lookups). | Client behavior and UX. |

---

## 2. Per-layer responsibilities

### 2.1 IcoAtlas — Company data (source of truth)

- **Base URL:** `https://icoatlas.sk`
- **Company lookup:** `GET https://icoatlas.sk/api/company/{ico}`
- **Scope:** All **factual** company data (name, address, IČO, DIČ, etc.).
- **Rule:** No other system is the source of truth for company data. The Flutter app and the Next.js gateway must use this API for company facts (or a cached copy derived from it).

### 2.2 Firebase — Auth, users, subscriptions, snapshots

- **Auth:** Sign-in, sign-up, sessions.
- **Users:** User profiles and app-specific user data.
- **Subscriptions:** Entitlements and paywall state.
- **Firestore:** User-owned documents (invoices, expenses, settings) and **optional** cache snapshots (e.g. company lookup cache in `companies/{ico}`). Firestore is not the source of truth for company data; it is a cache that can be refilled from IcoAtlas.

### 2.3 Next.js gateway — AI, lead magnet, monetization

- **AI Verdict:** Generation and delivery of AI verdicts (e.g. company health / risk).
- **Public lead magnet API:** Public-facing endpoints for lead generation (e.g. limited lookups, landing pages). When company data is needed, the gateway should call IcoAtlas (or use its own cache backed by IcoAtlas).
- **Monetization logic:** Subscription checks, usage limits, paywall decisions. May call Firebase (Auth/Subscriptions) and IcoAtlas as needed.

### 2.4 Flutter app — PRO client

- **UI and UX:** All screens, navigation, and user interactions.
- **Orchestration:** Calls IcoAtlas for company lookup; uses Firebase for auth and Firestore; uses the gateway for AI verdict, lead magnet flows, and monetization.
- **Caching:** May cache company data (e.g. in Firestore) with TTL; on cache miss or expiry, data is refetched from IcoAtlas only. No legacy “demo vs real” data-source flags (e.g. `ICO_MODE=REAL`); company data always comes from IcoAtlas (or its cache).

---

## 3. Data flow (high level)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Flutter app (PRO client)                            │
│  • UI, routing, Firestore cache (e.g. companies/{ico})                     │
└───────┬─────────────────────────┬─────────────────────────┬────────────────┘
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│  IcoAtlas     │         │  Firebase     │         │  Next.js      │
│  icoatlas.sk  │         │  Auth,        │         │  gateway      │
│               │         │  Firestore,   │         │  (e.g.        │
│  Company      │         │  Subscriptions│         │  bizagent.sk) │
│  data only    │         │               │         │               │
│  /api/company/│         │  users,       │         │  • AI Verdict │
│  {ico}        │         │  invoices,    │         │  • Lead magnet│
│               │         │  expenses,    │         │  • Monetization│
│  (single      │         │  cache docs   │         │               │
│   source of   │         │               │         │  (calls       │
│   truth)      │         │               │         │  IcoAtlas for │
└───────────────┘         └───────────────┘         │  company data)│
                                                     └───────────────┘
```

- **Company lookup path:** App → IcoAtlas `GET /api/company/{ico}` (optionally with Firestore cache in front). Gateway, when it needs company data, → IcoAtlas (or its own cache backed by IcoAtlas).
- **Auth / user data:** App → Firebase (Auth + Firestore).
- **AI / lead magnet / monetization:** App → Next.js gateway; gateway may call Firebase and IcoAtlas.

---

## 4. Rules and constraints

1. **Company data:** IcoAtlas (`https://icoatlas.sk/api/company/{ico}`) is the **only** source of truth. No duplicate authority (e.g. no “real” company data from another API).
2. **No legacy data-source flags:** Remove client flags that switch company data source (e.g. `ICO_MODE=REAL`). The client always uses IcoAtlas (or a cache of it) for company data.
3. **Firebase:** Used only for auth, users, subscriptions, and Firestore snapshots (including optional company cache). Not the source of truth for company registry.
4. **Gateway:** Does not replace IcoAtlas for company facts; it may proxy or cache IcoAtlas and is responsible for AI verdict, lead magnet API, and monetization.

---

## 5. Implementation notes (Flutter)

- **IcoAtlasService** (or equivalent) uses base URL `https://icoatlas.sk` for company lookup. No `isDemoMode` / `ICO_MODE` that change the company data source.
- **CompanyLookupService** (or equivalent) can use Firestore as a cache; on miss or expiry it calls IcoAtlas only.
- **Autocomplete / VIES:** If the app needs autocomplete or VIES, they can be implemented via the Next.js gateway (optional `GATEWAY_BASE_URL`) so that company **registry** remains IcoAtlas-only; gateway can call IcoAtlas and expose these features.

---

*Last updated: Normalized BizAgent architecture; icoatlas.sk as single source of truth for company data.*

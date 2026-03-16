# Roadmap

> **DeelMarkt** — Phased development roadmap

---

## Phase 0 — Foundation (Months −6 to 0) 🔄

### Business
- [ ] Register Holding BV + Operations BV at KVK
- [ ] Engage Dutch tech/privacy law firm
- [ ] 50+ user interviews
- [ ] Publish privacy policy + accessibility statement
- [ ] Contract pentest firm; obtain cyber insurance

### Development → Epics E01–E07
- [ ] Supabase + Firebase + Cloudflare + Cloudinary + Upstash + Unleash setup → **E07**
- [ ] Flutter monorepo: Clean Architecture + Riverpod 3 + GoRouter → **E07**
- [ ] CI/CD pipeline + Universal Links + App Links → **E07**
- [ ] Supabase Auth + iDIN/itsme KYC Levels 0–2 → **E02**
- [ ] Listing CRUD + PostgreSQL FTS + search outbox + image pipeline → **E01**
- [ ] Mollie escrow + double-entry ledger + idempotency → **E03**
- [ ] Supabase Realtime messaging → **E04**
- [ ] PostNL/DHL QR shipping + address API → **E05**
- [ ] AI scam detection + dispute resolution + ratings + DSA module → **E06**

### Go-to-Market
- [ ] Seed 500+ listings manually
- [ ] Sign 50–100 seller partners
- [ ] WhatsApp referral waitlist (target: 2K)
- [ ] ASO assets

---

## Phase 1 — Soft Launch Amsterdam (Months 0–3) ⏳

**Target:** 2,000 listings | 500 MAU | 200 transactions | NPS > 40

- [ ] Invite-only; zero fees
- [ ] Founders review every listing; resolve every dispute
- [ ] Complete pentest; remediate findings
- [ ] Weekly NPS; 20+ user interviews/month

---

## Phase 2 — Amsterdam Open (Months 3–9) ⏳

**Target:** 20,000 listings | 5,000 MAU | NPS > 50

- [ ] Open registration; 2–3 categories
- [ ] **Search upgrade: Meilisearch** for typo tolerance and autocomplete (self-hosted Railway ~$15–20/mo or Cloud $30/mo)
  - Note: ADR-004 references Typesense (Phase 1) → Elasticsearch (Phase 3+). Meilisearch is the Phase 2 bridge: simpler ops than ES, better typo tolerance than PostgreSQL FTS. Update ADR-004 to reflect this three-stage evolution.
- [ ] Migrate chat → Stream Chat SDK at ~1K MAU
- [ ] Introduce promoted listings (€0.99–€4.99) → **E08**
- [ ] Snap-to-List AI + smart pricing → **E08**
- [ ] CO2 savings calculator + eco-score badges → **E08**
- [ ] PostHog replaces Firebase Analytics → **E08**
- [ ] KYC Level 3 (Onfido)
- [ ] Hire: Trust & Safety, Growth, UX Designer
- [ ] Seed fundraising round (€1.5M–€3M) — begin at Month 9

---

## Phase 3 — Randstad (Months 9–18) ⏳

**Target:** 100K listings | 50K MAU

- [ ] Rotterdam, Den Haag, Utrecht, Eindhoven
- [ ] Transaction fees: 2.5% + €0.50; shipping commission 7%
- [ ] Business subscriptions → **E08**
- [ ] NestJS Modular Monolith migration (Strangler Fig) from Supabase Edge Functions
- [ ] Debezium + Kafka CDC pipeline (replaces outbox poller; <500ms sync)
- [ ] Personalised recommendations (Two-Tower) → **E08**
- [ ] AI Behavioural Scoring (Phase 3) → **E08**

---

## Phase 4 — National + Belgium (Months 18–30) ⏳

**Target:** 500K+ listings | 200K+ MAU

- [ ] Full NL availability; evaluate Flanders
- [ ] DE/FR language support
- [ ] **Search: Elasticsearch** with compound-word decomposition at 10M+ listings (replaces Meilisearch)
- [ ] Visual search (CLIP + Pinecone) → **E08**
- [ ] Series A preparation

---

## Sprint 4 — E07 Foundation 🔄

> First implementation sprint. Single-developer sequential execution.
> See [SPRINT-PLAN.md](SPRINT-PLAN.md) for task details and [PLAN](archives/sprint4-plan/PLAN-sprint4-scope-session-sync.md) for scope rationale.

| Phase | Task IDs | Area | Deliverable |
|:------|:---------|:-----|:------------|
| A — Design Foundation | `P-01` – `P-04` | Fonts, icons, i18n | Plus Jakarta Sans, Phosphor Icons, NL/EN localisation |
| B — UI Components | `P-05` – `P-09` | Shared widgets | DeelButton, DeelInput, SkeletonLoader, EmptyState, ErrorState |
| C — Supabase Bootstrap | `R-01` – `R-06` | Backend infra | Project, Auth, RLS, Vault, Storage, Realtime |
| D — Firebase + Edge Fn | `R-07` – `R-09` | Integrations | Health check Edge Function, FCM, Crashlytics |
| E — Infrastructure | `B-01` – `B-03` | DNS/CDN/Images | Cloudflare DNS+WAF, Cloudinary pipeline |
| F — CI/CD Pipeline | `B-04` – `B-05` | Automation | GitHub Actions CI, Codemagic builds |

---

## Completed

- [x] **Sprint 3** (2026-03-16): Architecture docs, epics, tech stack evaluation
- [x] **Sprint 2** (2026-03-15): Rebrand to DeelMarkt, domains acquired
- [x] **Sprint 1** (2026-03-14): Git repo, AI Kit setup

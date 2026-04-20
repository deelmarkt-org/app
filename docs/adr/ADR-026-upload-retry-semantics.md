# ADR-026: Photo Upload Retry Semantics — Typed `retryAfter` + Server-Hint Clamping

### Status

**Accepted** — 2026-04-20 · Author: reso · Tracker: GitHub issue [#131](https://github.com/deelmarkt-org/app/issues/131) · Supersedes PR #112 hardcoded-2s workaround

### Context

`PhotoUploadQueue` retries failed uploads with exponential backoff + full jitter. PR #112
introduced a 2 s fixed floor when the server returns HTTP 429 (rate-limited) so that
the client honours Supabase Edge Function throttling. Issue #131 flagged four defects
in that first cut:

1. **C2 (Clean Architecture violation)** — The PR plan proposed regex-parsing
   `AppException.debugMessage` to extract the server's `retry_after_seconds` hint.
   Parsing a free-form debug string leaks presentation-shaped contract into the
   domain layer and is brittle against i18n or refactors.
2. **H1 (Security / DoS)** — A hostile or buggy server could send
   `retry_after_seconds: 86400` (24 h). With no client-side cap the wizard would
   silently stall for an entire day.
3. **H2 (Observability gap)** — Retries were invisible in production. On-call had
   no signal when a backend rate-limit storm began degrading the sell flow.
4. **H3 (Accessibility gap, EAA §10)** — Screen readers announced "Uploading…"
   throughout a 30 s backoff. Blind users had no feedback that the attempt had
   failed and was being retried — breaching WCAG 2.2 SC 4.1.3 (status messages).

The R-27 specification (§3.6) requires a minimum 2 s floor between rate-limited
retries but does not specify the upper bound, total budget, or typed contract.

### Decision

Codify retry semantics with four architectural decisions:

1. **Typed `Duration? retryAfter` field** on `ValidationException`. The data-layer
   mapper (`image_upload_error_mapper.dart`) parses the server JSON and constructs
   the exception. The domain layer (`PhotoUploadQueue`) consumes the typed value.
   `AppException.debugMessage` remains a human-readable diagnostic only.
2. **Server-hint clamping** in `PhotoUploadQueue`:
   - `rateLimitFloor = 2 s` — mirrors R-27 §3.6; also used when the server
     returns 429 without a hint.
   - `rateLimitCap = 30 s` — industry standard ceiling (GitHub, Stripe, Twilio
     client SDKs). Defuses hostile hints (H1).
   - `totalDeadline = 60 s` — absolute retry budget per job. Beyond this the
     queue emits `PhotoUploadFailed` so the UI can surface the error.
3. **Structured retry logging** via `AppLogger.warning` at every backoff
   boundary, with fields `{photoId, attempt, delayMs, rateLimited, cause}`.
   Feeds Sentry breadcrumbs and on-call dashboards.
4. **A11y live-region** for retry state. `PhotoUploadQueue` exposes
   `Stream<Set<String>> retryingIds`; UI switches the tile's `Semantics.label`
   to `sell.uploadRetrying` (NL + EN) while preserving `liveRegion: true`.

All four are implemented as a single cohesive change in the same PR as this ADR.

### Rationale

- **Typed contract over string-parsing.** Dart 3's `sealed class AppException`
  hierarchy is already the domain's error contract. Extending the shape beats
  reverse-engineering a debug string. Compile-time safety, static tooling, and
  trivial test ergonomics are the payoff.
- **Bounded retries.** Rate-limit hints are advisory, not authoritative. The
  client must protect the user even when the server is wrong.
- **Observability is a feature.** A retry loop that is invisible is a retry
  loop that can't be operated. Structured logs at boundary events are cheap
  and answer "why did the sell flow feel slow this morning?"
- **A11y is a legal requirement.** EAA enforceability (2025-06-28) means silent
  retries against a blank screen-reader output is a compliance defect, not a
  nice-to-have.

### Alternatives Considered

1. **Regex-parse `debugMessage` to extract the hint** (C2 original proposal).
   Rejected — cross-layer coupling, regex drift on i18n, no compile-time
   guarantees. See §Context.
2. **New `RateLimitException extends AppException`.** Rejected — every retry
   call site would grow a new `case` in an already-wide `switch`. The hint is
   a *property* of a validation failure, not a new failure category. The typed
   optional field composes without pattern-matching explosion.
3. **No client-side cap, trust the server.** Rejected — one misconfigured
   deploy or a rogue response would produce a 24 h UI stall. The cap is
   defensive hygiene.
4. **Per-attempt `totalDeadline` instead of global.** Rejected — a global
   budget matches user perception of "how long am I waiting?" and is easier
   to reason about in tests.
5. **Emit retry state via a separate `Provider` rather than a `Stream` on the
   queue.** Rejected — the queue owns the retrying-set lifecycle (add on
   backoff start, clear on success/cancel/failure). Splitting ownership would
   create dual-write hazards.

### Consequences

#### Positive
- Clean Architecture preserved — presentation depends on typed domain shapes,
  not string formats.
- DoS vector closed — 30 s cap + 60 s total deadline bounds worst-case UI stall.
- On-call can now see retry storms in production logs.
- EAA-compliant retry announcement covers the previously silent backoff window.
- `computeDelay` is a pure static — deterministic unit tests without fake timers.

#### Negative
- One new optional field on `ValidationException` — backward-compatible default
  `null`, but every construction site reviewed to ensure the hint is forwarded
  when available. Mapper tests cover null-body / malformed / negative / string-
  numeric variants.
- New `Stream` on the queue — one more subscription for the UI to manage.
  Mitigated by exposing `currentRetryingIds` snapshot for initial sync.
- `totalDeadline` creates a new failure mode ("retry budget exhausted") that
  must be surfaced in telemetry distinct from "attempt budget exhausted."
  Covered by `_logRetryBudgetExhausted` with a distinct log key.

### Security

- **Hostile server hints clamped** to `[2 s, 30 s]` per attempt, `60 s` total.
- **No PII in logs** — only photoId (a UUID), attempt count, delay, exception
  runtime type, and a boolean `rateLimited` flag. No URL, no filename, no
  user id.
- **No retry on terminal errors** (`isRetryable == false`). `ValidationException`s
  like `error.image.too_large` or `error.image.unsupported_format` fail fast.

### Observability

Log events emitted from `PhotoUploadQueue`:

| Event | Tag | Fields |
|:------|:----|:-------|
| `upload_retry` | `photo-upload-queue` | photoId, attempt/max, delayMs, rateLimited, cause |
| `upload_retry_budget_exhausted` | `photo-upload-queue` | photoId, attempt/max, totalDeadlineSec, cause |

Downstream: both events already flow into Sentry breadcrumbs via the existing
`AppLogger.warning` bridge (see `lib/core/services/app_logger.dart`). No new
telemetry plumbing required.

### Rollback

Single-revert safe. Consumers:

- `ValidationException.retryAfter` has a `null` default — existing callers that
  construct the exception without the field remain valid.
- `retryingIds` stream — if reverted, the grid tile falls back to the plain
  `sell.uploadingImage` label (behaviour prior to this PR).
- `computeDelay` — reverting restores the jitter-only delay; functional
  correctness preserved (retries still happen, just without the floor).

Revert command: `git revert <merge-commit>` followed by regenerating
`.g.dart` via `dart run build_runner build --delete-conflicting-outputs`.

### Related

- ADR-022 — Image delivery pipeline (sibling decision for the read-path cache).
- R-27 — Image upload pipeline spec (`docs/specs/R-27-image-upload.md` §3.6).
- GitHub issue [#131](https://github.com/deelmarkt-org/app/issues/131) — tracker.
- PR #112 — original 2 s floor this ADR expands on.

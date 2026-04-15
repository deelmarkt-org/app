# ASO Claims Ledger

> Every marketing claim must map to a shipped feature in this ledger.
> **CLAUDE.md §13**: AI agents must not modify this file without explicit human approval.
> Last reviewed: 2026-04-15 (pizmam)

---

| Claim | Source Text | Code Path | Shipped? | Review Notes |
|-------|-------------|-----------|----------|--------------|
| "Veilig betalen via escrow" | NL description §1 | `lib/features/transactions/domain/entities/transaction_entity.dart` → `TransactionStatus.inEscrow` | ✅ Yes | E03 escrow flow |
| "iDIN verificatie" | NL description §2, keywords | `lib/features/auth/domain/entities/kyc_status.dart` → `KycStatus.verified` | ✅ Yes | E02 KYC flow |
| "QR-code verzenden via PostNL" | NL description §3 | `lib/features/shipping/presentation/screens/shipping_qr_screen.dart` | ✅ Yes | E05 shipping |
| "Trustscore op elk profiel" | NL description §4 | `lib/features/profile/domain/entities/user_profile_entity.dart` → `trustScore` | ✅ Yes | E02 trust score |
| "Veilige chat" | NL description §5 | `lib/features/chat/presentation/screens/chat_thread_screen.dart` | ✅ Yes | E04 messaging |
| "Gratis advertentie plaatsen" | NL description (sellers) | `lib/features/sell/presentation/screens/listing_creation_screen.dart` | ✅ Yes | E01 listings |
| "Betaling gegarandeerd" | NL description (sellers) | Escrow release flow in transactions | ✅ Yes | E03 |
| "Kopersbescherming inbegrepen" | NL description (buyers) | Dispute/escrow refund path | ⚠️ Partial | Dispute resolution UI not shipped in v1.0 — soften claim before submission |
| "Safe buy sell with escrow" | EN description §1 | Same as NL escrow | ✅ Yes | |
| "iDIN identity standard" | EN description §2 | Same as NL iDIN | ✅ Yes | |
| "Fully trackable parcels" | EN description §3 | PostNL tracking via `trackingNumber` field | ✅ Yes | |
| "Trust score" | EN description §4 | Same as NL trust score | ✅ Yes | |
| "Buyer protection included" | EN description (buyers) | Same as "Kopersbescherming" — ⚠️ | ⚠️ Partial | See above |

---

## Action Items Before App Store Submission

- [ ] **Soften "Kopersbescherming inbegrepen" / "Buyer protection included"**
  - Change to: "Escrow beschermt jouw betaling" / "Escrow protects your payment"
  - Rationale: Full dispute resolution UI not in v1.0
  - Owner: pizmam
  - Target: before first TestFlight external review

---

## How to Add a New Claim

1. Add a row to this table with the exact wording from the copy file
2. Link to the code file + entity/method that implements it
3. Mark `Shipped?` as ✅/⚠️/❌
4. Get approval from at least one other developer before publishing

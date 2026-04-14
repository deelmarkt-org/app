/// Transaction lifecycle states for the escrow payment flow.
///
/// State machine:
/// ```
/// created → payment_pending → paid → shipped → delivered → confirmed → released
///                  ↓                                           ↓
///              expired/failed                              disputed → resolved
///                                                                  → refunded
/// ```
///
/// Reference: docs/epics/E03-payments-escrow.md
enum TransactionStatus {
  /// Order created, awaiting payment initiation.
  created,

  /// Payment initiated via Mollie, waiting for buyer to complete.
  paymentPending,

  /// Payment completed. Funds held in escrow.
  paid,

  /// Seller shipped the item. Tracking active.
  shipped,

  /// Item delivered (PostNL tracking event). 48-hour confirmation window starts.
  delivered,

  /// Buyer confirmed receipt. Escrow release initiated.
  confirmed,

  /// Funds released to seller (minus commission). Terminal state.
  released,

  /// Payment expired (buyer didn't complete). Terminal state.
  expired,

  /// Payment failed at Mollie. Terminal state.
  failed,

  /// Buyer flagged issue within 48-hour window. Under review.
  disputed,

  /// Dispute resolved — funds released to seller. Terminal state.
  resolved,

  /// Dispute resolved — refund issued to buyer. Terminal state.
  refunded,

  /// Buyer cancelled before payment completed. Terminal state.
  cancelled;

  /// Whether this status represents a terminal (final) state.
  bool get isTerminal => switch (this) {
    released || expired || failed || resolved || refunded || cancelled => true,
    _ => false,
  };

  /// Whether funds are currently held in escrow.
  bool get isEscrowHeld => switch (this) {
    paid || shipped || delivered || confirmed || disputed => true,
    _ => false,
  };

  /// Valid transitions from this status.
  Set<TransactionStatus> get validTransitions => switch (this) {
    created => {paymentPending, cancelled},
    paymentPending => {paid, expired, failed, cancelled},
    paid => {shipped},
    shipped => {delivered},
    delivered => {confirmed, disputed},
    confirmed => {released},
    disputed => {resolved, refunded},
    _ => <TransactionStatus>{}, // Terminal states have no transitions
  };

  /// Whether transitioning to [next] is allowed.
  bool canTransitionTo(TransactionStatus next) =>
      validTransitions.contains(next);

  /// Convert to DB snake_case value.
  String toDb() => switch (this) {
    TransactionStatus.paymentPending => 'payment_pending',
    _ => name,
  };

  /// Parse from DB snake_case value.
  /// Unknown values default to [created] for forward-compatibility.
  static TransactionStatus fromDb(String value) => switch (value) {
    'created' => TransactionStatus.created,
    'payment_pending' => TransactionStatus.paymentPending,
    'paid' => TransactionStatus.paid,
    'shipped' => TransactionStatus.shipped,
    'delivered' => TransactionStatus.delivered,
    'confirmed' => TransactionStatus.confirmed,
    'released' => TransactionStatus.released,
    'expired' => TransactionStatus.expired,
    'failed' => TransactionStatus.failed,
    'disputed' => TransactionStatus.disputed,
    'resolved' => TransactionStatus.resolved,
    'refunded' => TransactionStatus.refunded,
    'cancelled' => TransactionStatus.cancelled,
    _ => TransactionStatus.created,
  };
}

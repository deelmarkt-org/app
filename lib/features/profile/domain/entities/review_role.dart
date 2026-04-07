/// Role of the reviewer in the transaction.
///
/// Extracted from [ReviewEntity] to satisfy the 100-line entity file limit
/// (CLAUDE.md §2.1). Re-exported via [ReviewEntity]'s library so all existing
/// importers remain compatible without change.
enum ReviewRole { buyer, seller }

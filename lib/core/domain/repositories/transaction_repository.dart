// Barrel re-export for cross-feature access (CLAUDE.md §11).
//
// Features that need [TransactionRepository] import this file instead of
// reaching into `features/transaction/` directly.
export 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

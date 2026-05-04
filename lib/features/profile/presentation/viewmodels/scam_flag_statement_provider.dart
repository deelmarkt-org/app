import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/domain/entities/scam_flag_statement.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/profile/data/dto/scam_flag_statement_dto.dart';

part 'scam_flag_statement_provider.g.dart';

/// Returns the affected user's most recent active [ScamFlagStatement] via
/// the `get_active_scam_flag(uuid)` RPC, or `null` if no active flag.
///
/// Composed alongside [activeSanctionProvider] in [SuspensionGateScreen]
/// so the DSA Art. 17 panel renders only when the moderation pipeline has
/// recorded an automated decision against the user. The two providers are
/// kept separate (rather than stuffing `scam_flag` into `account_sanctions`)
/// because they're separate aggregates with separate RPCs, separate RLS,
/// and separate refresh cadences (issue #259 §Architecture).
///
/// `null` is the safe default when the table is empty (R-44 backend shipped
/// with no writer integration yet — `scam_detection` EF still writes only
/// to `moderation_queue`). The conditional render in the suspension gate
/// harmlessly skips the panel until the writer lands.
///
/// Reference:
///  - supabase/migrations/20260503161500_r44_scam_flags.sql
///  - docs/audits/2026-04-25-tier1-retrospective.md §R-44
///  - issue #259
@riverpod
Future<ScamFlagStatement?> scamFlagStatement(
  ScamFlagStatementRef ref,
  String userId,
) async {
  final client = ref.watch(supabaseClientProvider);
  final raw = await client.rpc(
    'get_active_scam_flag',
    params: {'p_user_id': userId},
  );
  return ScamFlagStatementDto.fromJsonOrNull(raw);
}

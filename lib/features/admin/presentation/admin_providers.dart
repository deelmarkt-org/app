import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_activity_usecase.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:deelmarkt/features/admin/domain/usecases/verify_admin_role_usecase.dart';

part 'admin_providers.g.dart';

// Use case providers live in presentation because they wire domain to presentation.
// This mirrors the pattern in other features (e.g. sell_providers.dart,
// seller_home_notifier.dart). Repository providers remain in core/services.
// See docs/adr/ADR-002-admin-usecase-layer.md for rationale.

/// Provides [GetAdminStatsUseCase] — wired to the admin repository.
@riverpod
GetAdminStatsUseCase getAdminStatsUseCase(Ref ref) =>
    GetAdminStatsUseCase(ref.watch(adminRepositoryProvider));

/// Provides [GetAdminActivityUseCase] — wired to the admin repository.
@riverpod
GetAdminActivityUseCase getAdminActivityUseCase(Ref ref) =>
    GetAdminActivityUseCase(ref.watch(adminRepositoryProvider));

/// Provides [VerifyAdminRoleUseCase] — server-side admin role verification.
///
/// Only called when [FeatureFlags.adminServerVerify] is enabled.
/// Requires reso to deploy `public.is_admin()` SQL function first.
/// See docs/adr/ADR-001-reactive-auth-guard.md and
/// docs/security/threat-model-auth.md (E1, S1).
@Riverpod(keepAlive: true)
VerifyAdminRoleUseCase verifyAdminRoleUseCase(Ref ref) =>
    VerifyAdminRoleUseCase(ref.watch(adminRepositoryProvider));

import 'package:deelmarkt/features/admin/domain/repositories/admin_repository.dart';

/// Verifies that the current user holds the admin role via a server-side check.
///
/// Primary purpose: prevent privilege escalation via client-side metadata
/// tampering (threat E1 in docs/security/threat-model-auth.md).
///
/// ## Caching
///
/// Results are cached for [cacheDuration] (default 5 minutes) so the guard
/// does not generate a round-trip on every navigation event.
///
/// On mismatch (client says admin, server says no), call
/// `supabase.auth.refreshSession()` to sync the JWT claims, then log at
/// `CRITICAL` severity (see §12.1 observability requirements).
///
/// ## Feature flag gating
///
/// Gated behind [FeatureFlags.adminServerVerify] in the router.
/// Only enabled after reso deploys `public.is_admin()` to production.
/// See docs/adr/ADR-001-reactive-auth-guard.md §Compliance.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class VerifyAdminRoleUseCase {
  VerifyAdminRoleUseCase(
    this._repository, {
    Duration cacheDuration = const Duration(minutes: 5),
  }) : _cacheDuration = cacheDuration;

  final AdminRepository _repository;
  final Duration _cacheDuration;

  DateTime? _lastVerifiedAt;
  bool _cachedResult = false;

  /// Returns true if the server confirms the current user is an admin.
  ///
  /// Returns cached result if last verification was within [_cacheDuration].
  Future<bool> call() async {
    final now = DateTime.now();
    if (_lastVerifiedAt != null &&
        now.difference(_lastVerifiedAt!) < _cacheDuration) {
      return _cachedResult;
    }
    _cachedResult = await _repository.verifyAdminRole();
    _lastVerifiedAt = now;
    return _cachedResult;
  }

  /// Invalidates the cache — call after [supabase.auth.refreshSession()] to
  /// force a fresh server check on the next navigation event.
  void invalidate() {
    _lastVerifiedAt = null;
    _cachedResult = false;
  }
}

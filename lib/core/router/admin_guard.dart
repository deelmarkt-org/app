import 'package:supabase_flutter/supabase_flutter.dart';

/// Checks whether the current Supabase user has admin role.
///
/// Admin role is set via `app_metadata.role = 'admin'` using
/// the `set_admin_role()` RPC (service-role only).
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
bool isAdmin(User? user) {
  if (user == null) return false;
  final role = user.appMetadata['role'];
  return role == 'admin';
}

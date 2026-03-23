import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

part 'supabase_service.g.dart';

/// Initialise Supabase once in `main()` before `runApp`.
Future<void> initSupabase() async {
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
}

/// Provides the global [SupabaseClient] — overridable in tests.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(SupabaseClientRef ref) {
  return Supabase.instance.client;
}

/// Stream of auth state changes — for redirect guards.
@riverpod
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
}

/// Provides the current auth user (nullable) — reactive via auth state stream.
@riverpod
User? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull?.session?.user;
}

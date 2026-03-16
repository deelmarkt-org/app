import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design_system/theme.dart';
import 'core/router/app_router.dart';

/// Riverpod provider for GoRouter — single instance, testable via overrides.
final routerProvider = Provider((ref) => createRouter());

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DeelMarktApp()));
}

class DeelMarktApp extends ConsumerWidget {
  const DeelMarktApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DeelMarkt',
      debugShowCheckedModeBanner: false,
      theme: DeelmarktTheme.light,
      darkTheme: DeelmarktTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

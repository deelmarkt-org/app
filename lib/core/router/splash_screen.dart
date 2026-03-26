import 'package:flutter/material.dart';

import '../design_system/colors.dart';

/// Minimal splash screen shown while auth state loads.
///
/// Prevents flash of unauthenticated content (FOUC) on app start.
/// Replaced by home or onboarding once auth state resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? DeelmarktColors.darkScaffold : DeelmarktColors.white,
      body: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

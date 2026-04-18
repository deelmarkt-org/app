import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Minimal splash screen shown while auth state loads.
///
/// Prevents flash of unauthenticated content (FOUC) on app start.
/// Replaced by home or onboarding once auth state resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Semantics(
          label: 'a11y.loading'.tr(),
          child: const CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }
}

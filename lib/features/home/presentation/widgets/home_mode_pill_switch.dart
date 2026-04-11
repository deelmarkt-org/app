import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';
import 'package:deelmarkt/features/home/presentation/home_mode_notifier.dart';

/// Buyer/Seller pill toggle in the home app bar.
///
/// Audit A1: hidden when the user is not authenticated — unauthenticated
/// visitors always see buyer mode and the toggle is not offered.
/// Follows the [LanguageSwitch] SegmentedButton pattern.
/// Active segment uses primary (orange) fill per design spec.
/// Minimum 44px touch target per CLAUDE.md SS10.
///
/// Reference: docs/screens/02-home/designs/seller_mode_home_mobile_light/
class HomeModePillSwitch extends ConsumerWidget {
  const HomeModePillSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Audit A1: hide toggle for unauthenticated users.
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final mode = ref.watch(homeModeNotifierProvider);

    return Semantics(
      label: 'a11y.modeSwitch'.tr(),
      child: SegmentedButton<HomeMode>(
        segments: [
          ButtonSegment(value: HomeMode.buyer, label: Text('mode.buyer'.tr())),
          ButtonSegment(
            value: HomeMode.seller,
            label: Text('mode.seller'.tr()),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (selected) {
          ref.read(homeModeNotifierProvider.notifier).setMode(selected.first);
        },
        showSelectedIcon: false,
      ),
    );
  }
}

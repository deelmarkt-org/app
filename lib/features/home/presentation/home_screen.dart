import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';
import 'package:deelmarkt/features/home/presentation/home_mode_notifier.dart';
import 'package:deelmarkt/features/home/presentation/home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_data_view.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_home_data_view.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_home_empty_view.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_home_loading_view.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_sliver_app_bar.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';

/// Home screen — buyer or seller mode based on [HomeModeNotifier].
///
/// Audit finding A1: toggle hidden when unauthenticated.
/// Audit finding A5: AnimatedSwitcher for mode transition.
///
/// Route: `/` (root, inside bottom nav shell).
///
/// Reference: docs/screens/02-home/01-home-buyer.md
/// Reference: docs/screens/02-home/02-home-seller.md
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(homeModeNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Audit A1: unauthenticated users always see buyer mode.
    final effectiveMode = currentUser == null ? HomeMode.buyer : mode;

    // Audit A5: animated crossfade between modes.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          effectiveMode == HomeMode.seller
              ? const _SellerMode(key: ValueKey('seller'))
              : const _BuyerMode(key: ValueKey('buyer')),
    );
  }
}

class _BuyerMode extends ConsumerWidget {
  const _BuyerMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return homeState.when(
      loading: () => const _BuyerLoadingView(),
      error:
          (error, _) => ErrorState(
            onRetry: () => ref.read(homeNotifierProvider.notifier).refresh(),
          ),
      data: (data) => HomeDataView(data: data),
    );
  }
}

class _SellerMode extends ConsumerWidget {
  const _SellerMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerState = ref.watch(sellerHomeNotifierProvider);

    return sellerState.when(
      loading: () => const SellerHomeLoadingView(),
      error:
          (error, _) => ErrorState(
            onRetry:
                () => ref.read(sellerHomeNotifierProvider.notifier).refresh(),
          ),
      data: (data) {
        if (data.isEmpty) {
          return SellerHomeEmptyView(userName: data.userName);
        }
        // M6: "Nieuwe advertentie" is a full-width pill button above the
        // listings list, matching the design spec. FAB removed to avoid
        // overlap with the bottom nav bar on small screens.
        return SellerHomeDataView(data: data);
      },
    );
  }
}

class _BuyerLoadingView extends StatelessWidget {
  const _BuyerLoadingView();

  static const _skeletonCount = 6;

  @override
  Widget build(BuildContext context) {
    // M7: buyer loading view now includes the SliverAppBar so logo + pill
    // switch persist through the loading→data transition without flickering.
    return Semantics(
      label: 'a11y.loading'.tr(),
      child: CustomScrollView(
        slivers: [
          const HomeSliverAppBar(),
          AdaptiveListingGrid(
            padding: const EdgeInsets.all(Spacing.s4),
            itemCount: _skeletonCount,
            itemBuilder: (_, _) => const SkeletonListingCard(),
          ),
        ],
      ),
    );
  }
}

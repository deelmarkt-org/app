import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';

import 'package:deelmarkt/features/home/presentation/home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_data_view.dart';

/// Home screen (buyer mode) — B-50.
///
/// Sections: categories → trust banner → nearby grid → recent row.
/// Route: `/` (root, inside bottom nav shell).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return homeState.when(
      loading: () => const _LoadingView(),
      error:
          (error, _) => ErrorState(
            onRetry: () => ref.read(homeNotifierProvider.notifier).refresh(),
          ),
      data: (data) => HomeDataView(data: data),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  static const _skeletonCount = 6;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = Breakpoints.isCompact(context) ? 2 : 3;

    return Semantics(
      label: 'a11y.loading'.tr(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(Spacing.s4),
            sliver: SliverGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: Spacing.s3,
              crossAxisSpacing: Spacing.s3,
              childAspectRatio: 0.7,
              children: List.generate(
                _skeletonCount,
                (_) => const SkeletonListingCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

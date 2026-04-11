import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/action_required_section.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_mode_pill_switch.dart';
import 'package:deelmarkt/features/home/presentation/widgets/section_header.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_listing_tile.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_stats_row.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Seller mode home data view — greeting, stats, actions, my listings.
///
/// CustomScrollView with RefreshIndicator. ~180 lines per plan.
///
/// Reference: docs/screens/02-home/designs/seller_mode_home_mobile_light/
class SellerHomeDataView extends ConsumerWidget {
  const SellerHomeDataView({required this.data, super.key});

  final SellerHomeState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(sellerHomeNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          _appBar(context),
          _greeting(context),
          _stats(),
          if (data.actions.isNotEmpty) _actions(context),
          _newListingButton(context),
          _listingsHeader(context),
          _listingsList(context),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.s16)),
        ],
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: Text(
        'app.name'.tr(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      actions: const [HomeModePillSwitch(), SizedBox(width: Spacing.s3)],
    );
  }

  Widget _greeting(BuildContext context) {
    final name = data.userName ?? 'mode.seller'.tr();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.s4,
          Spacing.s4,
          Spacing.s4,
          Spacing.s2,
        ),
        child: Text(
          'home.seller.hello'.tr(args: [name]),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _stats() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.s4, bottom: Spacing.s6),
        child: SellerStatsRow(stats: data.stats),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.s6),
        child: ActionRequiredSection(
          actions: data.actions,
          onActionTap: (action) => _handleActionTap(context, action),
        ),
      ),
    );
  }

  Widget _newListingButton(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.s4,
          Spacing.s2,
          Spacing.s4,
          Spacing.s4,
        ),
        child: DeelButton(
          label: 'home.seller.newListing'.tr(),
          onPressed: () => context.go(AppRoutes.sell),
        ),
      ),
    );
  }

  Widget _listingsHeader(BuildContext context) {
    // TODO(P-54): add filter/sort icon affordance next to "Mijn advertenties"
    // matching the design — see seller_mode_home_mobile_light/screen.png.
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.s3),
        child: SectionHeader(title: 'home.seller.myListings'.tr()),
      ),
    );
  }

  Widget _listingsList(BuildContext context) {
    return SliverList.builder(
      itemCount: data.listings.length,
      itemBuilder: (context, index) {
        final listing = data.listings[index];
        return SellerListingTile(
          listing: listing,
          onTap:
              () => context.goNamed(
                'listing-detail',
                pathParameters: {'id': listing.id},
              ),
        );
      },
    );
  }

  void _handleActionTap(BuildContext context, ActionItemEntity action) {
    switch (action.type) {
      // B1 fix: referenceId is a transaction ID, not a shipping label ID.
      // Navigate to transaction detail where the user can open the shipping
      // flow. A direct /shipping/:labelId route requires resolving the label
      // by transaction ID first (tracked as P-54 follow-up).
      case ActionItemType.shipOrder:
        context.push(AppRoutes.transactionDetailFor(action.referenceId));
      case ActionItemType.replyMessage:
        context.push(AppRoutes.chatThreadFor(action.referenceId));
    }
  }
}

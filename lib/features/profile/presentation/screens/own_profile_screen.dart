import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/listings_tab_view.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_header.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_tabs.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/reviews_tab_view.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/verification_badges_row.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

/// Own profile screen — displays avatar, badges, stats, and tabbed content.
///
/// Reference: docs/screens/07-profile/01-own-profile.md
class OwnProfileScreen extends ConsumerStatefulWidget {
  const OwnProfileScreen({super.key});

  @override
  ConsumerState<OwnProfileScreen> createState() => _OwnProfileScreenState();
}

class _OwnProfileScreenState extends ConsumerState<OwnProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('profile.title'.tr()),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.gear()),
            tooltip: 'settings.title'.tr(),
            onPressed: () => context.push('${AppRoutes.profile}/settings'),
          ),
        ],
      ),
      body: state.user.when(
        loading: () => const ProfileSkeleton(),
        error: (_, _) => Center(child: Text('error.generic'.tr())),
        data: (user) => _buildBody(context, state, user),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileState state,
    UserEntity? user,
  ) {
    if (user == null) {
      return Center(child: Text('profile.notLoggedIn'.tr()));
    }

    return ResponsiveBody(
      maxWidth: 900,
      child: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.s4,
                    Spacing.s4,
                    Spacing.s4,
                    0,
                  ),
                  child: Column(
                    children: [
                      ProfileHeader(user: user),
                      const SizedBox(height: Spacing.s4),
                      VerificationBadgesRow(badges: user.badges),
                      const SizedBox(height: Spacing.s4),
                      ProfileStatsRow(user: user),
                      const SizedBox(height: Spacing.s6),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedTabsDelegate(
                  ProfileTabs(controller: _tabController),
                ),
              ),
            ],
        body: Padding(
          padding: const EdgeInsets.only(top: Spacing.s4),
          child: TabBarView(
            controller: _tabController,
            children: [
              ListingsTabView(
                listings: state.listings,
                onRetry: () => ref.invalidate(profileNotifierProvider),
              ),
              ReviewsTabView(
                reviews: state.reviews,
                onRetry: () => ref.invalidate(profileNotifierProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps [ProfileTabs] pinned while the header scrolls away.
class _PinnedTabsDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTabsDelegate(this.tabs);

  final Widget tabs;

  // ProfileTabs is a TabBar — 48px is Flutter's default tab bar height.
  static const double _height = 48;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(color: Theme.of(context).scaffoldBackgroundColor, child: tabs);

  @override
  bool shouldRebuild(_PinnedTabsDelegate oldDelegate) =>
      oldDelegate.tabs != tabs;
}

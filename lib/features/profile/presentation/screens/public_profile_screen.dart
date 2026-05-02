import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/listings_tab_view.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/public_profile_header.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/public_profile_more_actions.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/public_profile_skeleton.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/reviews_tab_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

/// Public seller profile screen (P-39).
///
/// Displays user info, verification badges, aggregate rating, stats,
/// and tabbed listings/reviews. Each section loads independently.
///
/// Reference: docs/epics/E06-trust-moderation.md §Public Profile
class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen>
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
    final state = ref.watch(publicProfileNotifierProvider(widget.userId));
    final notifier = ref.read(
      publicProfileNotifierProvider(widget.userId).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('seller_profile.title'.tr()),
        actions: [PublicProfileMoreButton(userId: widget.userId)],
      ),
      body: state.user.when(
        loading: () => const PublicProfileSkeleton(),
        error:
            (_, _) => ErrorState(
              message: 'error.generic'.tr(),
              onRetry: notifier.refresh,
            ),
        data: (user) {
          if (user == null) {
            return ErrorState(
              message: 'seller_profile.not_found'.tr(),
              onRetry: notifier.refresh,
            );
          }
          return _buildDataBody(user, state, notifier);
        },
      ),
    );
  }

  Widget _buildDataBody(
    UserEntity user,
    PublicProfileState state,
    PublicProfileNotifier notifier,
  ) {
    return ResponsiveBody.wide(
      maxWidth: 900,
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        // `NestedScrollView` lets the header + tabs slivers scroll away
        // *together* with the active tab's `CustomScrollView` body, instead
        // of the previous `SliverFillRemaining(TabBarView(...))` layout
        // that produced two independent scroll axes. The inner
        // `ListingsTabView` / `ReviewsTabView` `CustomScrollView`s pick up
        // the `PrimaryScrollController` that `NestedScrollView` installs,
        // so paging through tabs no longer leaves the header pinned in
        // place (Gemini PR #217 round 2).
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
                        PublicProfileHeader(
                          user: user,
                          aggregate: state.aggregate,
                        ),
                        const SizedBox(height: Spacing.s6),
                        _buildTabs(),
                        const SizedBox(height: Spacing.s4),
                      ],
                    ),
                  ),
                ),
              ],
          body: TabBarView(
            controller: _tabController,
            children: [
              ListingsTabView(
                listings: state.listings,
                onRetry: notifier.refresh,
              ),
              ReviewsTabView(
                reviews: state.reviews,
                onRetry: notifier.refresh,
                hasMore: notifier.hasMoreReviews,
                isLoadingMore: notifier.isLoadingMore,
                onLoadMore: notifier.loadMoreReviews,
                onReport:
                    (review) => showReportReasonSheet(
                      context,
                      (reason) => notifier.reportReview(review.id, reason),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'seller_profile.tab_listings'.tr()),
        Tab(text: 'seller_profile.tab_reviews'.tr()),
      ],
    );
  }
}

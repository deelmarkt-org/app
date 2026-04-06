import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/listings_tab_view.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/public_profile_header.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/report_reason_sheet.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/reviews_tab_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
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
        title: Text('sellerProfile.title'.tr()),
        actions: [
          PopupMenuButton<_MenuAction>(
            icon: Icon(PhosphorIcons.dotsThreeVertical()),
            tooltip: 'sellerProfile.moreActions'.tr(),
            onSelected: (action) => _handleMenuAction(action, notifier),
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: _MenuAction.share,
                    child: Text('sellerProfile.shareAction'.tr()),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.report,
                    child: Text('sellerProfile.reportAction'.tr()),
                  ),
                ],
          ),
        ],
      ),
      body: state.user.when(
        loading: () => const _ProfileSkeleton(),
        error:
            (_, _) => ErrorState(
              message: 'error.generic'.tr(),
              onRetry: notifier.refresh,
            ),
        data: (user) {
          if (user == null) {
            return ErrorState(
              message: 'sellerProfile.notFound'.tr(),
              onRetry: notifier.refresh,
            );
          }

          return ResponsiveBody(
            child: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
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
                  SliverFillRemaining(
                    child: TabBarView(
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
                              (review) => _showReportSheet(
                                context,
                                (reason) =>
                                    notifier.reportReview(review.id, reason),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'sellerProfile.tabListings'.tr()),
        Tab(text: 'sellerProfile.tabReviews'.tr()),
      ],
    );
  }

  Future<void> _handleMenuAction(
    _MenuAction action,
    PublicProfileNotifier notifier,
  ) async {
    switch (action) {
      case _MenuAction.share:
        await notifier.shareProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('sellerProfile.shareCopied'.tr())),
        );
      case _MenuAction.report:
        _showReportSheet(context, (reason) => notifier.reportUser(reason));
    }
  }

  void _showReportSheet(
    BuildContext context,
    Future<void> Function(ReportReason) onSubmit,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ReportReasonSheet(onSubmit: onSubmit),
    );
  }
}

enum _MenuAction { share, report }

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerLow;
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s4),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(height: Spacing.s3),
            Container(width: 120, height: 16, color: color),
            const SizedBox(height: Spacing.s2),
            Container(width: 80, height: 12, color: color),
          ],
        ),
      ),
    );
  }
}

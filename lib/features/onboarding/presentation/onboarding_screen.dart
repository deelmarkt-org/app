import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/onboarding_content.dart';

/// Full onboarding flow — 3-page PageView with language selection,
/// trust value proposition, and account creation CTA.
///
/// Replaces the Phase 1 placeholder. Persists completion flag via
/// SharedPreferences so returning users skip onboarding.
///
/// - **Compact (<840px):** Full-screen PageView, centred at
///   [Breakpoints.contentMaxWidth] via [ResponsiveBody] (with
///   [ResponsiveBody.addHorizontalPadding] disabled — see
///   [OnboardingContent] for the padding contract).
/// - **Expanded (≥840px):** Content rendered inside a centred elevated
///   [Card] (max-width 720px) matching `onboarding_tablet_optimized_card`
///   design. Mobile layout is unchanged.
///
/// Route: `/onboarding` (auth guard redirects here when not logged in
/// and onboarding is not yet complete).
///
/// Reference: docs/screens/01-auth/01-onboarding.md
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageCount = 3;

  /// Max-width of the elevated Card on expanded viewports.
  /// Reference: docs/screens/01-auth/01-onboarding.md §Tablet, issue #196.
  static const double _tabletCardMaxWidth = 720;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_onPageChanged)
      ..dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round();
    if (page != null &&
        page != ref.read(onboardingNotifierProvider).currentPage) {
      ref.read(onboardingNotifierProvider.notifier).setPage(page);
    }
  }

  Future<void> _completeAndNavigate(String route) async {
    try {
      await ref.read(onboardingNotifierProvider.notifier).completeOnboarding();
      if (mounted) context.go(route);
    } on Exception catch (e) {
      AppLogger.error(
        'Failed to complete onboarding',
        tag: 'onboarding',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error.generic'.tr())));
      }
    }
  }

  void _nextPage() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _pageController.nextPage(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousPage() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _pageController.previousPage(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final isExpanded = Breakpoints.isExpanded(context);

    return PopScope(
      canPop: state.currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previousPage();
      },
      child: Scaffold(
        body: SafeArea(
          child:
              isExpanded
                  ? _buildExpandedLayout(state)
                  : _buildCompactLayout(state),
        ),
      ),
    );
  }

  /// Compact layout: full-screen PageView centred at contentMaxWidth.
  ///
  /// `ResponsiveBody.addHorizontalPadding` is disabled so the inner
  /// 16-px button padding inside [OnboardingContent] is the sole
  /// horizontal gutter — see the class docstring on [OnboardingContent]
  /// for the full padding contract.
  Widget _buildCompactLayout(OnboardingState state) {
    return ResponsiveBody(
      maxWidth: Breakpoints.contentMaxWidth,
      addHorizontalPadding: false,
      child: _buildContent(state, isExpanded: false),
    );
  }

  /// Expanded layout: content inside a centred elevated Card at 720px.
  Widget _buildExpandedLayout(OnboardingState state) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _tabletCardMaxWidth),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildContent(state, isExpanded: true),
        ),
      ),
    );
  }

  Widget _buildContent(OnboardingState state, {required bool isExpanded}) {
    return OnboardingContent(
      currentPage: state.currentPage,
      pageCount: _pageCount,
      pageController: _pageController,
      isExpanded: isExpanded,
      onSkip: () => _completeAndNavigate(AppRoutes.register),
      onNext: _nextPage,
      onCreateAccount: () => _completeAndNavigate(AppRoutes.register),
      onLogin: () => _completeAndNavigate(AppRoutes.login),
    );
  }
}

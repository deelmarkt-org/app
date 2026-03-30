import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'onboarding_notifier.dart';
import 'widgets/get_started_page.dart';
import 'widgets/onboarding_trust_badges.dart';
import 'widgets/page_dot_indicator.dart';
import 'widgets/trust_page.dart';
import 'widgets/welcome_page.dart';

/// Full onboarding flow — 3-page PageView with language selection,
/// trust value proposition, and account creation CTA.
///
/// Replaces the Phase 1 placeholder. Persists completion flag via
/// SharedPreferences so returning users skip onboarding.
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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
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
    } catch (e) {
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
          child: ResponsiveBody(
            maxWidth: 500,
            child: Column(
              children: [
                // Header (expanded breakpoint only): logo + skip
                if (isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: Spacing.s4,
                      bottom: Spacing.s2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'app.name'.tr(),
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        DeelButton(
                          label: 'onboarding.skip'.tr(),
                          onPressed:
                              () => _completeAndNavigate(AppRoutes.register),
                          variant: DeelButtonVariant.ghost,
                          size: DeelButtonSize.small,
                          fullWidth: false,
                        ),
                      ],
                    ),
                  ),
                ],

                // PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      const WelcomePage(),
                      const TrustPage(),
                      GetStartedPage(
                        onCreateAccount:
                            () => _completeAndNavigate(AppRoutes.register),
                        onLogin: () => _completeAndNavigate(AppRoutes.login),
                      ),
                    ],
                  ),
                ),

                // Dot indicator
                const SizedBox(height: Spacing.s6),
                PageDotIndicator(
                  currentPage: state.currentPage,
                  pageCount: _pageCount,
                ),

                // "Volgende" button (pages 0-1 only — WCAG 2.5.7 swipe alternative)
                if (state.currentPage < _pageCount - 1) ...[
                  const SizedBox(height: Spacing.s4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
                    child: DeelButton(
                      label: 'onboarding.next'.tr(),
                      onPressed: _nextPage,
                      variant: DeelButtonVariant.primary,
                      size: DeelButtonSize.large,
                    ),
                  ),
                ],

                // Trust badges (expanded only)
                const SizedBox(height: Spacing.s6),
                const OnboardingTrustBadges(),
                const SizedBox(height: Spacing.s4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

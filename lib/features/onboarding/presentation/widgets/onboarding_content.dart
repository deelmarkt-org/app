import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/get_started_page.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/onboarding_trust_badges.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/page_dot_indicator.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/trust_page.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/welcome_page.dart';

/// Shared column body for [OnboardingScreen]'s compact and expanded
/// layouts: optional header → 3-page PageView → dot indicator →
/// conditional "Next" button → trust badges.
///
/// Padding contract — important for layout parity:
/// - the inner "Next" button has its own `Padding(horizontal:
///   Spacing.s4)` so it gets a 16-px gutter regardless of which layout
///   wraps the column;
/// - the **compact** path therefore disables `ResponsiveBody`'s default
///   16-px screen margin (`addHorizontalPadding: false`) so the two
///   sources don't stack to 32 px;
/// - the **expanded** path renders inside a `Card` whose `Clip.antiAlias`
///   leaves no outer padding, so the inner 16-px is the sole gutter
///   there too. Both paths produce a consistent 16-px button inset
///   (Gemini PR #217 round 2).
///
/// Reference: docs/screens/01-auth/01-onboarding.md
class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    required this.currentPage,
    required this.pageCount,
    required this.pageController,
    required this.isExpanded,
    required this.onSkip,
    required this.onNext,
    required this.onCreateAccount,
    required this.onLogin,
    super.key,
  });

  final int currentPage;
  final int pageCount;
  final PageController pageController;
  final bool isExpanded;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isExpanded) _buildHeader(context),
        Expanded(child: _buildPageView()),
        const SizedBox(height: Spacing.s6),
        PageDotIndicator(currentPage: currentPage, pageCount: pageCount),
        if (currentPage < pageCount - 1) ...[
          const SizedBox(height: Spacing.s4),
          // The horizontal padding here is the canonical button gutter on
          // both compact and expanded layouts — see class docstring on
          // [OnboardingContent].
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
            child: DeelButton(label: 'onboarding.next'.tr(), onPressed: onNext),
          ),
        ],
        const SizedBox(height: Spacing.s6),
        const OnboardingTrustBadges(),
        const SizedBox(height: Spacing.s4),
      ],
    );
  }

  /// Header (expanded breakpoint only): app name + skip button.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: Spacing.s4,
        left: Spacing.s4,
        right: Spacing.s4,
        bottom: Spacing.s2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'app.name'.tr(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          DeelButton(
            label: 'onboarding.skip'.tr(),
            onPressed: onSkip,
            variant: DeelButtonVariant.ghost,
            size: DeelButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  PageView _buildPageView() {
    return PageView(
      controller: pageController,
      physics: const ClampingScrollPhysics(),
      children: [
        const WelcomePage(),
        const TrustPage(),
        GetStartedPage(onCreateAccount: onCreateAccount, onLogin: onLogin),
      ],
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_mode_pill_switch.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Empty state for seller mode — new seller with no listings.
///
/// Shows greeting + illustration + "Start met verkopen" CTA.
/// Audit finding A6: this view is shown only when listings.isEmpty,
/// NOT when stats are zero (zero sales with listings = normal data view).
///
/// Reference: docs/screens/02-home/designs/seller_mode_home_empty_state/
class SellerHomeEmptyView extends ConsumerWidget {
  const SellerHomeEmptyView({this.userName, super.key});

  final String? userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        _appBar(context),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spacing.s4),
                _greeting(context),
                const Spacer(),
                _illustration(context, isDark),
                const Spacer(),
                SafeArea(
                  child: DeelButton(
                    label: 'home.seller.startSelling'.tr(),
                    onPressed: () => context.go(AppRoutes.sell),
                    leadingIcon: PhosphorIcons.plus(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _appBar(BuildContext context) {
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
    final name = userName ?? 'mode.seller'.tr();
    return Text(
      'home.seller.hello'.tr(args: [name]),
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _illustration(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color:
                  isDark
                      ? DeelmarktColors.darkSurface
                      : DeelmarktColors.neutral100,
              borderRadius: BorderRadius.circular(DeelmarktRadius.xxl),
            ),
            child: Icon(
              PhosphorIcons.package(),
              size: 40,
              color:
                  isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral300,
            ),
          ),
          const SizedBox(height: Spacing.s6),
          Text(
            'home.seller.emptyTitle'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.s3),
          Text(
            'home.seller.emptySubtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

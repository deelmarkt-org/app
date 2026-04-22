import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_mode_pill_switch.dart';

/// Shared floating [SliverAppBar] for the Home feature.
///
/// Renders the "DeelMarkt" app name in the primary colour with bold weight,
/// followed by the [HomeModePillSwitch] and any [extraActions] supplied by
/// the caller. Extracted from five near-identical `_appBar()` methods that
/// previously lived in `home_data_view`, `seller_home_data_view`,
/// `seller_home_empty_view`, `seller_home_loading_view`, and the buyer
/// loading view inside `home_screen`.
///
/// Lives inside the Home feature (not `lib/widgets/`) because every consumer
/// is a Home screen and the widget embeds the feature-owned
/// [HomeModePillSwitch] — keeping it here preserves §1.2: `lib/widgets/`
/// must remain feature-agnostic.
///
/// Reference: docs/screens/02-home/01-home-buyer.md
/// Reference: docs/screens/02-home/02-home-seller.md
class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({this.extraActions = const <Widget>[], super.key});

  /// Additional action widgets placed after the mode pill.
  ///
  /// The buyer data view uses this for the favourites, search and
  /// notifications icon buttons; the seller views and loading views
  /// leave it empty.
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      floating: true,
      title: Text(
        'app.name'.tr(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
      actions: [
        const HomeModePillSwitch(),
        if (extraActions.isEmpty)
          const SizedBox(width: Spacing.s3)
        else ...[
          const SizedBox(width: Spacing.s2),
          ...extraActions,
        ],
      ],
    );
  }
}

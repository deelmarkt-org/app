import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/router/routes.dart';

/// Icon buttons (favourites, search, notifications) shown in the buyer-mode
/// home app bar. Extracted into a dedicated `const` widget so the parent
/// data view does not rebuild a fresh list of [IconButton]s on every
/// Riverpod state emission.
class HomeBuyerAppBarActions extends StatelessWidget {
  const HomeBuyerAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(PhosphorIcons.heart()),
          tooltip: 'favourites.title'.tr(),
          onPressed: () => context.push(AppRoutes.favourites),
        ),
        IconButton(
          icon: Icon(PhosphorIcons.magnifyingGlass()),
          tooltip: 'nav.search'.tr(),
          onPressed: () => context.go(AppRoutes.search),
        ),
        IconButton(
          icon: Icon(PhosphorIcons.bell()),
          tooltip: 'nav.notifications'.tr(),
          onPressed: null, // Phase 2: wire to notifications (R-34)
        ),
      ],
    );
  }
}

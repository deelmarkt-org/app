import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/router/routes.dart';

/// Orange FAB for creating a new listing in seller mode.
///
/// White plus icon on orange circle. Navigates to `/sell`.
/// Positioned by Scaffold.floatingActionButton in HomeScreen.
///
/// Reference: docs/screens/02-home/designs/seller_mode_home_mobile_light/
class NewListingFab extends StatelessWidget {
  const NewListingFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'home.seller.newListing'.tr(),
      child: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.sell),
        backgroundColor: DeelmarktColors.primary,
        foregroundColor: DeelmarktColors.white,
        icon: Icon(PhosphorIcons.plus()),
        label: Text('home.seller.newListing'.tr()),
      ),
    );
  }
}

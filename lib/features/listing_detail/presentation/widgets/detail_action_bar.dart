import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/shadows.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Sticky bottom action bar.
///
/// Shows Message + Buy for other users' listings,
/// or Edit + Delete for the current user's own listing.
/// Hidden when the listing is sold.
///
/// Height: 72px + safe area bottom inset.
class DetailActionBar extends StatelessWidget {
  const DetailActionBar({
    required this.priceInCents,
    this.isOwnListing = false,
    this.onMessage,
    this.onBuy,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final int priceInCents;
  final bool isOwnListing;
  final VoidCallback? onMessage;
  final VoidCallback? onBuy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static const double _barHeight = 72;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      height: _barHeight + bottomPadding,
      padding: EdgeInsets.only(
        left: Spacing.s4,
        right: Spacing.s4,
        top: Spacing.s3,
        bottom: Spacing.s3 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: DeelmarktShadows.elevation1,
      ),
      child: isOwnListing ? _ownListingButtons() : _buyerButtons(),
    );
  }

  Widget _buyerButtons() {
    return Row(
      children: [
        Expanded(
          child: DeelButton(
            label: 'listing_detail.messageButton'.tr(),
            onPressed: onMessage,
            variant: DeelButtonVariant.secondary,

            leadingIcon: PhosphorIcons.chatCircle(),
          ),
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: DeelButton(
            label: 'listing_detail.buyButton'.tr(
              namedArgs: {'price': Formatters.euroFromCents(priceInCents)},
            ),
            onPressed: onBuy,
          ),
        ),
      ],
    );
  }

  Widget _ownListingButtons() {
    return Row(
      children: [
        Expanded(
          child: DeelButton(
            label: 'action.edit'.tr(),
            onPressed: onEdit,
            variant: DeelButtonVariant.outline,

            leadingIcon: PhosphorIcons.pencilSimple(),
          ),
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: DeelButton(
            label: 'action.delete'.tr(),
            onPressed: onDelete,
            variant: DeelButtonVariant.destructive,
          ),
        ),
      ],
    );
  }
}

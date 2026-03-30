import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

/// Variant showcase — all 6 button variants at medium size.
class VariantSection extends StatelessWidget {
  const VariantSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s3,
      runSpacing: Spacing.s3,
      children: [
        DeelButton(label: 'Primary', onPressed: () {}),
        DeelButton(
          label: 'Secondary',
          variant: DeelButtonVariant.secondary,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Outline',
          variant: DeelButtonVariant.outline,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Ghost',
          variant: DeelButtonVariant.ghost,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Destructive',
          variant: DeelButtonVariant.destructive,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Success',
          variant: DeelButtonVariant.success,
          onPressed: () {},
        ),
      ],
    );
  }
}

/// Size showcase — all 3 sizes in primary variant.
class SizeSection extends StatelessWidget {
  const SizeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s3,
      runSpacing: Spacing.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DeelButton(
          label: 'Small',
          size: DeelButtonSize.small,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Medium',
          size: DeelButtonSize.medium,
          onPressed: () {},
        ),
        DeelButton(label: 'Large', onPressed: () {}),
      ],
    );
  }
}

/// Icon showcase — leading, trailing, combined with Phosphor icons.
class IconSection extends StatelessWidget {
  const IconSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s3,
      runSpacing: Spacing.s3,
      children: [
        DeelButton(
          label: 'Add Listing',
          leadingIcon: PhosphorIcons.plus(),
          onPressed: () {},
        ),
        DeelButton(
          label: 'Next Step',
          trailingIcon: PhosphorIcons.arrowRight(),
          onPressed: () {},
        ),
        DeelButton(
          label: 'Favorite',
          leadingIcon: PhosphorIcons.heart(),
          variant: DeelButtonVariant.outline,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Delete',
          leadingIcon: PhosphorIcons.trash(),
          variant: DeelButtonVariant.destructive,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Published',
          leadingIcon: PhosphorIcons.checkCircle(),
          variant: DeelButtonVariant.success,
          onPressed: () {},
        ),
      ],
    );
  }
}

/// Full-width showcase.
class FullWidthSection extends StatelessWidget {
  const FullWidthSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DeelButton(
            label: 'Place Order',
            leadingIcon: PhosphorIcons.shoppingCart(),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: Spacing.s3),
        SizedBox(
          width: double.infinity,
          child: DeelButton(
            label: 'Processing Payment...',
            isLoading: true,
            loadingLabel: 'Processing payment',
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

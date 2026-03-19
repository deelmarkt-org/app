import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../widgets/buttons/buttons.dart';

/// Variant showcase — all 6 button variants at medium size.
class VariantSection extends StatelessWidget {
  const VariantSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s3,
      runSpacing: Spacing.s3,
      children: [
        DeelButton(
          label: 'Primary',
          variant: DeelButtonVariant.primary,
          onPressed: () {},
        ),
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
        DeelButton(
          label: 'Large',
          size: DeelButtonSize.large,
          onPressed: () {},
        ),
      ],
    );
  }
}

/// State showcase — enabled, disabled, loading.
class StateSection extends StatelessWidget {
  const StateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s3,
      runSpacing: Spacing.s3,
      children: [
        DeelButton(label: 'Enabled', onPressed: () {}),
        const DeelButton(label: 'Disabled', onPressed: null),
        DeelButton(
          label: 'Loading...',
          isLoading: true,
          loadingLabel: 'Processing',
          onPressed: () {},
        ),
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

/// Full-width showcase — full-width buttons with loading state.
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
            size: DeelButtonSize.large,
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
            size: DeelButtonSize.large,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

/// Disabled showcase — all variants in disabled state.
class DisabledSection extends StatelessWidget {
  const DisabledSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: Spacing.s3,
      runSpacing: Spacing.s3,
      children: [
        DeelButton(
          label: 'Primary',
          variant: DeelButtonVariant.primary,
          onPressed: null,
        ),
        DeelButton(
          label: 'Secondary',
          variant: DeelButtonVariant.secondary,
          onPressed: null,
        ),
        DeelButton(
          label: 'Outline',
          variant: DeelButtonVariant.outline,
          onPressed: null,
        ),
        DeelButton(
          label: 'Ghost',
          variant: DeelButtonVariant.ghost,
          onPressed: null,
        ),
        DeelButton(
          label: 'Destructive',
          variant: DeelButtonVariant.destructive,
          onPressed: null,
        ),
        DeelButton(
          label: 'Success',
          variant: DeelButtonVariant.success,
          onPressed: null,
        ),
      ],
    );
  }
}

/// Loading showcase — all variants in loading state.
class LoadingSection extends StatelessWidget {
  const LoadingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s3,
      runSpacing: Spacing.s3,
      children: [
        DeelButton(
          label: 'Primary',
          variant: DeelButtonVariant.primary,
          isLoading: true,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Secondary',
          variant: DeelButtonVariant.secondary,
          isLoading: true,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Outline',
          variant: DeelButtonVariant.outline,
          isLoading: true,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Ghost',
          variant: DeelButtonVariant.ghost,
          isLoading: true,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Destructive',
          variant: DeelButtonVariant.destructive,
          isLoading: true,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Success',
          variant: DeelButtonVariant.success,
          isLoading: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

/// Section title badge with design system tokens.
class ShowcaseSectionTitle extends StatelessWidget {
  const ShowcaseSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s3,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xs),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

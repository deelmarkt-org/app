import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

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

/// Disabled showcase — all variants in disabled state.
class DisabledSection extends StatelessWidget {
  const DisabledSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: Spacing.s3,
      runSpacing: Spacing.s3,
      children: [
        DeelButton(label: 'Primary', onPressed: null),
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
        DeelButton(label: 'Primary', isLoading: true, onPressed: () {}),
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

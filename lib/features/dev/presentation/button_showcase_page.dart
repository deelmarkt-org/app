import 'package:flutter/material.dart';

import '../../../widgets/buttons/buttons.dart';

/// Showcase page for DeelButton — demonstrates all variants, sizes, and states.
///
/// This is a development-only page used for visual verification.
/// Not included in production navigation.
class ButtonShowcasePage extends StatefulWidget {
  const ButtonShowcasePage({super.key});

  @override
  State<ButtonShowcasePage> createState() => _ButtonShowcasePageState();
}

class _ButtonShowcasePageState extends State<ButtonShowcasePage> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data:
          _isDarkMode
              ? Theme.of(context).copyWith(brightness: Brightness.dark)
              : Theme.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DeelButton Showcase'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              tooltip: 'Toggle theme',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, 'P-05 DeelButton — Component Showcase'),
              const SizedBox(height: 8),
              Text(
                '6 variants × 3 sizes × 5 states',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Variants (Medium size)'),
              const SizedBox(height: 16),
              const _VariantSection(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Sizes (Primary variant)'),
              const SizedBox(height: 16),
              const _SizeSection(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'States (Primary variant)'),
              const SizedBox(height: 16),
              const _StateSection(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'With Icons'),
              const SizedBox(height: 16),
              const _IconSection(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Full Width'),
              const SizedBox(height: 16),
              const _FullWidthSection(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'All Variants — Disabled'),
              const SizedBox(height: 16),
              const _DisabledSection(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'All Variants — Loading'),
              const SizedBox(height: 16),
              const _LoadingSection(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────

Widget _buildHeader(BuildContext context, String text) {
  return Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
  );
}

Widget _buildSectionTitle(BuildContext context, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

// ── Section Widgets ──────────────────────────────────────────────────────

class _VariantSection extends StatelessWidget {
  const _VariantSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
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

class _SizeSection extends StatelessWidget {
  const _SizeSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
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

class _StateSection extends StatelessWidget {
  const _StateSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
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

class _IconSection extends StatelessWidget {
  const _IconSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DeelButton(
          label: 'Add Listing',
          leadingIcon: Icons.add,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Next Step',
          trailingIcon: Icons.arrow_forward,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Favorite',
          leadingIcon: Icons.favorite,
          variant: DeelButtonVariant.outline,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Delete',
          leadingIcon: Icons.delete_outline,
          variant: DeelButtonVariant.destructive,
          onPressed: () {},
        ),
        DeelButton(
          label: 'Published',
          leadingIcon: Icons.check_circle_outline,
          variant: DeelButtonVariant.success,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _FullWidthSection extends StatelessWidget {
  const _FullWidthSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DeelButton(
            label: 'Place Order',
            leadingIcon: Icons.shopping_cart,
            size: DeelButtonSize.large,
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 12),
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

class _DisabledSection extends StatelessWidget {
  const _DisabledSection();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
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

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
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

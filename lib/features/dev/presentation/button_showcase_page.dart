import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/design_system/spacing.dart';
import 'widgets/showcase_state_sections.dart';
import 'widgets/showcase_variant_sections.dart';

/// Showcase page for DeelButton — demonstrates all variants, sizes, and states.
///
/// Development-only page for visual verification.
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
              icon: Icon(
                _isDarkMode ? PhosphorIcons.sun() : PhosphorIcons.moon(),
              ),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              tooltip: 'Toggle theme',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'P-05 DeelButton — Component Showcase',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Spacing.s2),
              Text(
                '6 variants × 3 sizes × 5 states',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: Spacing.s8),
              const ShowcaseSectionTitle('Variants (Medium size)'),
              const SizedBox(height: Spacing.s4),
              const VariantSection(),
              const SizedBox(height: Spacing.s8),
              const ShowcaseSectionTitle('Sizes (Primary variant)'),
              const SizedBox(height: Spacing.s4),
              const SizeSection(),
              const SizedBox(height: Spacing.s8),
              const ShowcaseSectionTitle('States (Primary variant)'),
              const SizedBox(height: Spacing.s4),
              const StateSection(),
              const SizedBox(height: Spacing.s8),
              const ShowcaseSectionTitle('With Icons'),
              const SizedBox(height: Spacing.s4),
              const IconSection(),
              const SizedBox(height: Spacing.s8),
              const ShowcaseSectionTitle('Full Width'),
              const SizedBox(height: Spacing.s4),
              const FullWidthSection(),
              const SizedBox(height: Spacing.s8),
              const ShowcaseSectionTitle('All Variants — Disabled'),
              const SizedBox(height: Spacing.s4),
              const DisabledSection(),
              const SizedBox(height: Spacing.s8),
              const ShowcaseSectionTitle('All Variants — Loading'),
              const SizedBox(height: Spacing.s4),
              const LoadingSection(),
              const SizedBox(height: Spacing.s12),
            ],
          ),
        ),
      ),
    );
  }
}

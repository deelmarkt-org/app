import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Predefined empty state variants for common screens.
///
/// Each variant resolves its own icon, message l10n key, and action l10n key.
/// Reference: docs/design-system/components.md §Empty States
enum EmptyStateVariant {
  search,
  favorites,
  messages,
  myListings,
  orders;

  /// Phosphor icon for the empty illustration.
  IconData get icon => switch (this) {
    search => PhosphorIcons.magnifyingGlass(),
    favorites => PhosphorIcons.heart(),
    messages => PhosphorIcons.chatCircle(),
    myListings => PhosphorIcons.package(),
    orders => PhosphorIcons.shoppingBag(),
  };

  /// L10n key for the empty message text.
  String get messageKey => switch (this) {
    search => 'empty.search',
    favorites => 'empty.favorites',
    messages => 'empty.messages',
    myListings => 'empty.my_listings',
    orders => 'empty.orders',
  };

  /// L10n key for the action button label.
  String get actionKey => switch (this) {
    search => 'empty.search_action',
    favorites => 'empty.favorites_action',
    messages => 'empty.messages_action',
    myListings => 'empty.my_listings_action',
    orders => 'empty.orders_action',
  };
}

/// Empty state widget with illustration, message, and action button.
///
/// "Never a blank screen. Always illustration + message + action button."
///
/// Two constructors:
/// - [EmptyState] — use a predefined [EmptyStateVariant]
/// - [EmptyState.custom] — provide custom icon, message, and action label
///
/// Reference: docs/design-system/components.md §Empty States
class EmptyState extends StatelessWidget {
  /// Creates an empty state from a predefined [variant].
  const EmptyState({required this.variant, required this.onAction, super.key})
    : _icon = null,
      _message = null,
      _actionLabel = null;

  /// Creates an empty state with custom icon, message, and action label.
  const EmptyState.custom({
    required IconData icon,
    required String message,
    required String actionLabel,
    required this.onAction,
    super.key,
  }) : variant = null,
       _icon = icon,
       _message = message,
       _actionLabel = actionLabel;

  /// Predefined variant. Null when using [EmptyState.custom].
  final EmptyStateVariant? variant;

  /// Action button callback.
  final VoidCallback onAction;

  final IconData? _icon;
  final String? _message;
  final String? _actionLabel;

  IconData get _resolvedIcon => _icon ?? variant!.icon;

  String get _resolvedMessage => _message ?? variant!.messageKey.tr();

  String get _resolvedActionLabel => _actionLabel ?? variant!.actionKey.tr();

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final iconColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;
    final message = _resolvedMessage;

    return Semantics(
      label: 'a11y.emptyState'.tr(args: [message]),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(_resolvedIcon, size: 32, color: iconColor),
              ),
              const SizedBox(height: Spacing.s4),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.s6),
              DeelButton(
                label: _resolvedActionLabel,
                onPressed: onAction,
                variant: DeelButtonVariant.secondary,
                size: DeelButtonSize.medium,
                fullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

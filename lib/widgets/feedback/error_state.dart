import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Error state widget with retry button and optional offline banner.
///
/// Standard usage: full-screen error with retry CTA.
///
/// Offline usage: shows a warning banner at the top. When [cachedContent]
/// is provided, renders it below the banner with a retry button at the bottom.
///
/// When [isOffline] is true and [cachedContent] is provided, this widget
/// uses [Expanded] — it MUST be placed inside a vertically bounded parent
/// (e.g., inside a [Scaffold.body] or a [SizedBox] with finite height).
///
/// Reference: docs/design-system/components.md §Error State
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.onRetry,
    this.message,
    this.isOffline = false,
    this.cachedContent,
    super.key,
  });

  /// Retry button callback. Always present.
  final VoidCallback onRetry;

  /// Error message. Defaults to the generic error l10n key.
  final String? message;

  /// Whether the device is offline. Shows warning banner when true.
  final bool isOffline;

  /// Cached content to display below offline banner.
  /// Only used when [isOffline] is true.
  final Widget? cachedContent;

  @override
  Widget build(BuildContext context) {
    if (isOffline) {
      return _buildOfflineLayout(context);
    }
    return _buildStandardLayout(context);
  }

  Widget _buildStandardLayout(BuildContext context) {
    final errorColor =
        _isDark(context) ? DeelmarktColors.darkError : DeelmarktColors.error;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warning(),
              size: 32,
              color: errorColor,
              semanticLabel: 'a11y.errorIcon'.tr(),
            ),
            const SizedBox(height: Spacing.s4),
            _buildErrorBody(context, fallbackKey: 'error.generic', maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineLayout(BuildContext context) {
    final isDark = _isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOfflineBanner(context, isDark: isDark),
        if (cachedContent != null)
          ..._buildCachedContentBody()
        else
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: _buildErrorBody(context, fallbackKey: 'error.network'),
              ),
            ),
          ),
      ],
    );
  }

  /// Offline warning banner with wifi-slash icon.
  Widget _buildOfflineBanner(BuildContext context, {required bool isDark}) {
    final bannerColor =
        isDark
            ? DeelmarktColors.darkWarningSurface
            : DeelmarktColors.warningSurface;
    final iconColor =
        isDark ? DeelmarktColors.darkOnSurface : DeelmarktColors.neutral700;

    return Container(
      color: bannerColor,
      padding: const EdgeInsets.all(Spacing.s3),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(PhosphorIcons.wifiSlash(), size: 20, color: iconColor),
          ),
          const SizedBox(width: Spacing.s2),
          Expanded(
            child: Text(
              'error.offline'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Cached content body with retry button at the bottom.
  List<Widget> _buildCachedContentBody() {
    return [
      Expanded(child: cachedContent!),
      Padding(padding: const EdgeInsets.all(Spacing.s4), child: _retryButton()),
    ];
  }

  /// Shared error message + retry button.
  Widget _buildErrorBody(
    BuildContext context, {
    required String fallbackKey,
    int? maxLines,
  }) {
    final resolvedMessage = message ?? fallbackKey.tr();
    final hasOverflow = maxLines != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            resolvedMessage,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
            maxLines: maxLines,
            overflow: hasOverflow ? TextOverflow.ellipsis : null,
          ),
        ),
        const SizedBox(height: Spacing.s6),
        _retryButton(fullWidth: false),
      ],
    );
  }

  /// Shared retry button — DRY across layouts.
  Widget _retryButton({bool fullWidth = true}) {
    return DeelButton(
      label: 'action.retry'.tr(),
      onPressed: onRetry,
      size: DeelButtonSize.medium,
      fullWidth: fullWidth,
    );
  }

  /// Theme brightness helper — reduces duplicate `Theme.of(context)` calls.
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

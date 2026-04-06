import 'package:easy_localization/easy_localization.dart';

/// Hand-rolled relative time formatter using l10n keys (NL + EN).
///
/// Uses easy_localization's active locale for all output — locale changes
/// at runtime are automatically reflected on next call.
///
/// Uses `intl` for locale-aware absolute date fallback.
///
/// Reference: docs/epics/E06-trust-moderation.md §Public Profile
String formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.isNegative) return _formatAbsolute(dateTime);

  final seconds = diff.inSeconds;
  final minutes = diff.inMinutes;
  final hours = diff.inHours;
  final days = diff.inDays;

  if (seconds < 60) return 'timeAgo.justNow'.tr();
  if (minutes == 1) return 'timeAgo.minuteAgo'.tr();
  if (minutes < 60) {
    return 'timeAgo.minutesAgo'.tr(namedArgs: {'n': '$minutes'});
  }
  if (hours == 1) return 'timeAgo.hourAgo'.tr();
  if (hours < 24) return 'timeAgo.hoursAgo'.tr(namedArgs: {'n': '$hours'});
  if (days == 1) return 'timeAgo.yesterday'.tr();
  if (days < 7) return 'timeAgo.daysAgo'.tr(namedArgs: {'n': '$days'});
  if (days < 14) return 'timeAgo.weekAgo'.tr();
  if (days < 30) {
    return 'timeAgo.weeksAgo'.tr(namedArgs: {'n': '${days ~/ 7}'});
  }
  if (days < 60) return 'timeAgo.monthAgo'.tr();
  if (days < 365) {
    return 'timeAgo.monthsAgo'.tr(namedArgs: {'n': '${days ~/ 30}'});
  }
  if (days < 730) return 'timeAgo.yearAgo'.tr();
  return _formatAbsolute(dateTime);
}

String _formatAbsolute(DateTime dt) {
  return DateFormat.yMMMM().format(dt);
}

/// Format a member-since date as "Lid sinds jan 2025" / "Member since Jan 2025".
///
/// Uses `intl` for locale-aware month formatting.
String formatMemberSince(DateTime date, {String locale = 'nl'}) {
  return DateFormat.yMMM(locale).format(date);
}

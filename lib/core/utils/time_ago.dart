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

  if (seconds < 60) return 'time_ago.just_now'.tr();
  if (minutes == 1) return 'time_ago.minute_ago'.tr();
  if (minutes < 60) {
    return 'time_ago.minutes_ago'.tr(namedArgs: {'n': '$minutes'});
  }
  if (hours == 1) return 'time_ago.hour_ago'.tr();
  if (hours < 24) return 'time_ago.hours_ago'.tr(namedArgs: {'n': '$hours'});
  if (days == 1) return 'time_ago.yesterday'.tr();
  if (days < 7) return 'time_ago.days_ago'.tr(namedArgs: {'n': '$days'});
  if (days < 14) return 'time_ago.week_ago'.tr();
  if (days < 30) {
    return 'time_ago.weeks_ago'.tr(namedArgs: {'n': '${days ~/ 7}'});
  }
  if (days < 60) return 'time_ago.month_ago'.tr();
  if (days < 365) {
    return 'time_ago.months_ago'.tr(namedArgs: {'n': '${days ~/ 30}'});
  }
  if (days < 730) return 'time_ago.year_ago'.tr();
  return _formatAbsolute(dateTime);
}

String _formatAbsolute(DateTime dt) {
  return DateFormat.yMMMM().format(dt);
}

/// Format a member-since date as "Lid sinds jan 2025" / "Member since Jan 2025".
///
/// Uses `intl` for locale-aware month formatting.
String formatMemberSince(DateTime date, {required String locale}) {
  return DateFormat.yMMM(locale).format(date);
}

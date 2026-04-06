import 'package:intl/intl.dart';

/// Hand-rolled relative time formatter for NL + EN.
///
/// No external dependency (timeago package not in pubspec).
/// Uses `intl` for locale-aware formatting of absolute dates as fallback.
///
/// Reference: docs/epics/E06-trust-moderation.md §Public Profile
String formatTimeAgo(DateTime dateTime, {String locale = 'nl'}) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.isNegative) return _formatAbsolute(dateTime, locale);

  final seconds = diff.inSeconds;
  final minutes = diff.inMinutes;
  final hours = diff.inHours;
  final days = diff.inDays;

  if (locale == 'nl') return _formatNl(seconds, minutes, hours, days, dateTime);
  return _formatEn(seconds, minutes, hours, days, dateTime);
}

String _formatNl(int s, int m, int h, int d, DateTime dt) {
  if (s < 60) return 'Zojuist';
  if (m == 1) return '1 minuut geleden';
  if (m < 60) return '$m minuten geleden';
  if (h == 1) return '1 uur geleden';
  if (h < 24) return '$h uur geleden';
  if (d == 1) return 'Gisteren';
  if (d < 7) return '$d dagen geleden';
  if (d < 14) return '1 week geleden';
  if (d < 30) return '${d ~/ 7} weken geleden';
  if (d < 60) return '1 maand geleden';
  if (d < 365) return '${d ~/ 30} maanden geleden';
  if (d < 730) return '1 jaar geleden';
  return _formatAbsolute(dt, 'nl');
}

String _formatEn(int s, int m, int h, int d, DateTime dt) {
  if (s < 60) return 'Just now';
  if (m == 1) return '1 minute ago';
  if (m < 60) return '$m minutes ago';
  if (h == 1) return '1 hour ago';
  if (h < 24) return '$h hours ago';
  if (d == 1) return 'Yesterday';
  if (d < 7) return '$d days ago';
  if (d < 14) return '1 week ago';
  if (d < 30) return '${d ~/ 7} weeks ago';
  if (d < 60) return '1 month ago';
  if (d < 365) return '${d ~/ 30} months ago';
  if (d < 730) return '1 year ago';
  return _formatAbsolute(dt, 'en');
}

String _formatAbsolute(DateTime dt, String locale) {
  return DateFormat.yMMMM(locale).format(dt);
}

/// Format a member-since date as "Lid sinds jan 2025" / "Member since Jan 2025".
///
/// Uses l10n keys `sellerProfile.memberSince` with `{date}` named arg.
/// Falls back to locale-specific prefix if easy_localization is unavailable.
String formatMemberSince(DateTime date, {String locale = 'nl'}) {
  return DateFormat.yMMM(locale).format(date);
}

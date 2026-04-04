import 'package:easy_localization/easy_localization.dart';

/// Formats [DateTime] values for the chat UI.
///
/// Returns a localised relative label:
///  - Same calendar day → `chat.today`
///  - Previous calendar day → `chat.yesterday`
///  - Within the last 7 days → weekday name (Maandag / Monday)
///  - Older → short date ("14 mrt 2026" / "Mar 14, 2026")
///
/// The caller passes `now` explicitly so tests can freeze time.
/// Pure Dart apart from the easy_localization key lookup.
abstract final class ChatDateFormatter {
  static String daySeparator(DateTime moment, {required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(moment.year, moment.month, moment.day);
    final diffDays = today.difference(thatDay).inDays;

    if (diffDays == 0) return 'chat.today'.tr();
    if (diffDays == 1) return 'chat.yesterday'.tr();
    if (diffDays > 1 && diffDays < 7) {
      return DateFormat.EEEE().format(moment);
    }
    return DateFormat.yMMMd().format(moment);
  }

  /// Compact row timestamp shown next to list items and bubbles.
  ///
  /// Same day → "HH:mm"; yesterday → `chat.yesterday`; within 7 days → weekday;
  /// older → short date.
  static String relativeRowTimestamp(DateTime moment, {required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(moment.year, moment.month, moment.day);
    final diffDays = today.difference(thatDay).inDays;

    if (diffDays == 0) return DateFormat.Hm().format(moment);
    if (diffDays == 1) return 'chat.yesterday'.tr();
    if (diffDays > 1 && diffDays < 7) {
      return DateFormat.EEEE().format(moment);
    }
    return DateFormat.yMd().format(moment);
  }

  /// Bubble-footer time ("HH:mm") — always the literal clock time.
  static String bubbleTime(DateTime moment) => DateFormat.Hm().format(moment);
}

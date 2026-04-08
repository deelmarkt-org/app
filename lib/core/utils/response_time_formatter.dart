import 'package:easy_localization/easy_localization.dart';

/// Shared response time formatting — maps minutes to l10n bucket strings.
///
/// Used by ProfileStatsRow and ChatHeader to ensure consistent bucket
/// boundaries and l10n key usage across the app. Extracted per §3.2 DRY.
///
/// Buckets: < 1h, < 4h, < 24h, > 24h, unknown (null).

/// Long-form label: "Responds within 1 hour" / "Reageert binnen 1 uur".
String formatResponseTimeLabel(int? minutes) {
  if (minutes == null) return 'seller_profile.response_time.unknown'.tr();
  if (minutes < 60) return 'seller_profile.response_time.under_1h'.tr();
  if (minutes < 240) return 'seller_profile.response_time.under_4h'.tr();
  if (minutes < 1440) return 'seller_profile.response_time.under_24h'.tr();
  return 'seller_profile.response_time.over_24h'.tr();
}

/// Short-form value: "< 1h" / "< 1u" (locale-aware).
String formatResponseTimeShort(int? minutes) {
  if (minutes == null) return '-';
  if (minutes < 60) {
    return 'seller_profile.response_time.short_under_1h'.tr();
  }
  if (minutes < 240) {
    return 'seller_profile.response_time.short_under_4h'.tr();
  }
  if (minutes < 1440) {
    return 'seller_profile.response_time.short_under_24h'.tr();
  }
  return 'seller_profile.response_time.short_over_24h'.tr();
}

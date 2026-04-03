import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/settings_section_header.dart';

/// Notifications section — toggle switches for 4 notification types.
///
/// Uses [SwitchListTile] with optimistic updates via [onChanged].
class NotificationsSection extends StatelessWidget {
  const NotificationsSection({
    required this.prefs,
    required this.onChanged,
    super.key,
  });

  final NotificationPreferences prefs;
  final ValueChanged<NotificationPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: 'settings.notifications'.tr()),
        SwitchListTile(
          title: Text('settings.messages'.tr()),
          value: prefs.messages,
          onChanged: (value) => onChanged(prefs.copyWith(messages: value)),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: Text('settings.offers'.tr()),
          value: prefs.offers,
          onChanged: (value) => onChanged(prefs.copyWith(offers: value)),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: Text('settings.shippingUpdates'.tr()),
          value: prefs.shippingUpdates,
          onChanged:
              (value) => onChanged(prefs.copyWith(shippingUpdates: value)),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: Text('settings.marketing'.tr()),
          value: prefs.marketing,
          onChanged: (value) => onChanged(prefs.copyWith(marketing: value)),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

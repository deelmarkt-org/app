import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/settings_viewmodel.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/account_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/addresses_section.dart';
import 'package:deelmarkt/core/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/address_form_modal.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/app_info_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/notifications_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/privacy_section.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/settings/language_switch.dart';

/// Settings screen.
///
/// Reference: docs/screens/07-profile/03-settings.md

/// App version provider — uses manual FutureProvider (leaf provider, no notifier dependencies).
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  } on Exception {
    return '1.0.0';
  }
});

/// Settings screen with 5 sections:
/// Account, Addresses, Notifications, Privacy, App Info.
///
/// Reference: docs/screens/07-profile/03-settings.md
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s4,
            vertical: Spacing.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LanguageSwitch(),
              const SizedBox(height: Spacing.s4),
              _buildAccountSection(profileState),
              _buildAddressesSection(state, ref, context),
              _buildNotificationsSection(state, ref),
              _buildPrivacySection(context, state, ref),
              AppInfoSection(version: version.valueOrNull ?? ''),
              const SizedBox(height: Spacing.s8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(ProfileState profileState) {
    return profileState.user.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return AccountSection(email: user.email ?? '', phone: user.phone ?? '');
      },
    );
  }

  Future<void> _saveAddressFromModal(
    BuildContext context,
    WidgetRef ref, {
    DutchAddress? existing,
  }) async {
    final result = await AddressFormModal.show(context, address: existing);
    if (result != null && context.mounted) {
      await ref.read(settingsNotifierProvider.notifier).saveAddress(result);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('settings.addressSaved'.tr())));
      }
    }
  }

  Widget _buildAddressesSection(
    SettingsState state,
    WidgetRef ref,
    BuildContext context,
  ) {
    return state.addresses.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text('error.generic'.tr()),
      data:
          (addresses) => AddressesSection(
            addresses: addresses,
            onAdd: () => _saveAddressFromModal(context, ref),
            onEdit:
                (address) =>
                    _saveAddressFromModal(context, ref, existing: address),
            onDelete:
                (address) => ref
                    .read(settingsNotifierProvider.notifier)
                    .deleteAddress(address),
          ),
    );
  }

  Widget _buildNotificationsSection(SettingsState state, WidgetRef ref) {
    return state.notificationPrefs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text('error.generic'.tr()),
      data:
          (prefs) => NotificationsSection(
            prefs: prefs,
            onChanged:
                (updated) => ref
                    .read(settingsNotifierProvider.notifier)
                    .updateNotificationPrefs(updated),
          ),
    );
  }

  Widget _buildPrivacySection(
    BuildContext context,
    SettingsState state,
    WidgetRef ref,
  ) {
    return PrivacySection(
      onExport:
          () => ref.read(settingsNotifierProvider.notifier).exportUserData(),
      onDeleteAccount: () async {
        final password = await DeleteAccountDialog.show(context);
        if (password != null && password.isNotEmpty && context.mounted) {
          await ref
              .read(settingsNotifierProvider.notifier)
              .deleteAccount(password: password);
        }
      },
      isExporting: state.isExporting,
      isDeleting: state.isDeleting,
    );
  }
}

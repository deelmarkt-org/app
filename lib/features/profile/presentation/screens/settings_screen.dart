import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/settings_viewmodel.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/account_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/addresses_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/app_info_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/address_form_modal.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/notifications_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/privacy_section.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/settings/language_switch.dart';

/// Settings screen with 5 sections:
/// Account, Addresses, Notifications, Privacy, App Info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } on Exception {
      if (mounted) setState(() => _version = '1.0.0');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final password = await DeleteAccountDialog.show(context);
    if (password != null && password.isNotEmpty && mounted) {
      await ref
          .read(settingsProvider.notifier)
          .deleteAccount(password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final profileState = ref.watch(profileProvider);

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
              _buildAddressesSection(state),
              _buildNotificationsSection(state),
              _buildPrivacySection(state),
              AppInfoSection(version: _version),
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

  Widget _buildAddressesSection(SettingsState state) {
    return state.addresses.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text('error.generic'.tr()),
      data:
          (addresses) => AddressesSection(
            addresses: addresses,
            onAdd: () async {
              final address = await AddressFormModal.show(context);
              if (address != null && mounted) {
                await ref.read(settingsProvider.notifier).saveAddress(address);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('settings.addressSaved'.tr())),
                  );
                }
              }
            },
            onEdit: (address) async {
              final updated = await AddressFormModal.show(
                context,
                address: address,
              );
              if (updated != null && mounted) {
                await ref.read(settingsProvider.notifier).saveAddress(updated);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('settings.addressSaved'.tr())),
                  );
                }
              }
            },
            onDelete:
                (address) =>
                    ref.read(settingsProvider.notifier).deleteAddress(address),
          ),
    );
  }

  Widget _buildNotificationsSection(SettingsState state) {
    return state.notificationPrefs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text('error.generic'.tr()),
      data:
          (prefs) => NotificationsSection(
            prefs: prefs,
            onChanged:
                (updated) => ref
                    .read(settingsProvider.notifier)
                    .updateNotificationPrefs(updated),
          ),
    );
  }

  Widget _buildPrivacySection(SettingsState state) {
    return PrivacySection(
      onExport: () => ref.read(settingsProvider.notifier).exportUserData(),
      onDeleteAccount: _handleDeleteAccount,
      isExporting: state.isExporting,
      isDeleting: state.isDeleting,
    );
  }
}

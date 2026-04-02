import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/settings_section_header.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Addresses section — list of saved addresses with add/edit/delete.
class AddressesSection extends StatelessWidget {
  const AddressesSection({
    required this.addresses,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<DutchAddress> addresses;
  final VoidCallback onAdd;
  final ValueChanged<DutchAddress> onEdit;
  final ValueChanged<DutchAddress> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: 'settings.addresses'.tr()),
        ...addresses.map(
          (address) => _AddressTile(
            address: address,
            theme: theme,
            onEdit: () => onEdit(address),
            onDelete: () => onDelete(address),
          ),
        ),
        const SizedBox(height: Spacing.s3),
        DeelButton(
          label: 'settings.addAddress'.tr(),
          onPressed: onAdd,
          variant: DeelButtonVariant.outline,
          size: DeelButtonSize.medium,
          leadingIcon: PhosphorIcons.plus(),
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  final DutchAddress address;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.s2),
      child: ListTile(
        title: Text(address.formatted, style: theme.textTheme.bodyMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(PhosphorIcons.pencilSimple()),
              onPressed: onEdit,
              tooltip: 'action.edit'.tr(),
            ),
            IconButton(
              icon: Icon(PhosphorIcons.trash(), color: theme.colorScheme.error),
              onPressed: onDelete,
              tooltip: 'action.delete'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

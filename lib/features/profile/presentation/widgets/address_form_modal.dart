import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/dutch_address_input.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

/// Modal bottom sheet for adding or editing a Dutch address.
///
/// - `address` null → add mode (empty fields)
/// - `address` non-null → edit mode (pre-filled fields)
///
/// Returns a [DutchAddress] via [onSave] when the user taps Save.
class AddressFormModal extends StatefulWidget {
  const AddressFormModal({this.address, required this.onSave, super.key});

  final DutchAddress? address;
  final ValueChanged<DutchAddress> onSave;

  /// Show the modal and return the saved address (or null if dismissed).
  static Future<DutchAddress?> show(
    BuildContext context, {
    DutchAddress? address,
  }) {
    return showModalBottomSheet<DutchAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return AddressFormModal(
          address: address,
          onSave: (saved) => Navigator.of(context).pop(saved),
        );
      },
    );
  }

  @override
  State<AddressFormModal> createState() => _AddressFormModalState();
}

class _AddressFormModalState extends State<AddressFormModal> {
  late final TextEditingController _postcodeController;
  late final TextEditingController _houseNumberController;
  late final TextEditingController _additionController;
  String? _street;
  String? _city;
  String? _postcodeError;
  String? _houseNumberError;

  bool get _isEditMode => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _postcodeController = TextEditingController(text: address?.postcode ?? '');
    _houseNumberController = TextEditingController(
      text: address?.houseNumber ?? '',
    );
    _additionController = TextEditingController(text: address?.addition ?? '');
    _street = address?.street;
    _city = address?.city;
  }

  @override
  void dispose() {
    _postcodeController.dispose();
    _houseNumberController.dispose();
    _additionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final postcode = _postcodeController.text.trim();
    final houseNumber = _houseNumberController.text.trim();

    // Validate required fields
    String? postcodeErr;
    String? houseNumberErr;

    if (postcode.isEmpty || postcode.length < 6) {
      postcodeErr = 'address.postcodeInvalid'.tr();
    }
    if (houseNumber.isEmpty) {
      houseNumberErr = 'address.houseNumberInvalid'.tr();
    }

    if (postcodeErr != null || houseNumberErr != null) {
      setState(() {
        _postcodeError = postcodeErr;
        _houseNumberError = houseNumberErr;
      });
      return;
    }

    final addition = _additionController.text.trim();
    final address = DutchAddress(
      postcode: postcode,
      houseNumber: houseNumber,
      addition: addition.isNotEmpty ? addition : null,
      street: _street ?? '',
      city: _city ?? '',
    );

    widget.onSave(address);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _isEditMode ? 'settings.editAddress'.tr() : 'settings.addAddress'.tr();

    return ResponsiveBody(
      child: Padding(
        padding: EdgeInsets.only(
          left: Spacing.s4,
          right: Spacing.s4,
          top: Spacing.s4,
          bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: Spacing.s4),
            DutchAddressInput(
              postcodeController: _postcodeController,
              houseNumberController: _houseNumberController,
              additionController: _additionController,
              street: _street,
              city: _city,
              postcodeError: _postcodeError,
              houseNumberError: _houseNumberError,
              onPostcodeChanged: (_) {
                if (_postcodeError != null) {
                  setState(() => _postcodeError = null);
                }
              },
              onHouseNumberChanged: (_) {
                if (_houseNumberError != null) {
                  setState(() => _houseNumberError = null);
                }
              },
            ),
            const SizedBox(height: Spacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('action.cancel'.tr()),
                ),
                const SizedBox(width: Spacing.s3),
                FilledButton(
                  onPressed: _handleSave,
                  child: Text('action.save'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

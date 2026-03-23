import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Dutch address input with 3 fields + auto-fill for street/city.
///
/// Layout adapts to screen width:
/// - compact (<600px): stacked fields
/// - medium+ (≥600px): postcode + house + addition in one row
///
/// Reference: docs/design-system/patterns.md §Dutch Address Input
class DutchAddressInput extends StatelessWidget {
  const DutchAddressInput({
    required this.postcodeController,
    required this.houseNumberController,
    this.additionController,
    this.street,
    this.city,
    this.isLoading = false,
    this.postcodeError,
    this.houseNumberError,
    this.onPostcodeChanged,
    this.onHouseNumberChanged,
    super.key,
  });

  final TextEditingController postcodeController;
  final TextEditingController houseNumberController;
  final TextEditingController? additionController;

  /// Auto-filled street name (null = not yet looked up).
  final String? street;

  /// Auto-filled city name (null = not yet looked up).
  final String? city;

  /// Whether address lookup is in progress.
  final bool isLoading;

  final String? postcodeError;
  final String? houseNumberError;

  /// Called when postcode changes (for triggering API lookup).
  final ValueChanged<String>? onPostcodeChanged;

  /// Called when house number changes (for triggering API lookup).
  final ValueChanged<String>? onHouseNumberChanged;

  @override
  Widget build(BuildContext context) {
    final isCompact = Breakpoints.isCompact(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCompact)
          ..._buildStackedFields(context)
        else
          _buildInlineRow(context),
        const SizedBox(height: Spacing.s3),
        _buildAutoFilledField(context, 'address.street'.tr(), street),
        const SizedBox(height: Spacing.s3),
        _buildAutoFilledField(context, 'address.city'.tr(), city),
      ],
    );
  }

  List<Widget> _buildStackedFields(BuildContext context) {
    return [
      _buildPostcodeField(context),
      const SizedBox(height: Spacing.s3),
      Row(
        children: [
          Expanded(flex: 2, child: _buildHouseNumberField(context)),
          const SizedBox(width: Spacing.s3),
          Expanded(child: _buildAdditionField(context)),
        ],
      ),
    ];
  }

  Widget _buildInlineRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildPostcodeField(context)),
        const SizedBox(width: Spacing.s3),
        Expanded(flex: 2, child: _buildHouseNumberField(context)),
        const SizedBox(width: Spacing.s3),
        Expanded(child: _buildAdditionField(context)),
      ],
    );
  }

  Widget _buildPostcodeField(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'address.postcode'.tr(),
      child: TextFormField(
        controller: postcodeController,
        decoration: InputDecoration(
          labelText: 'address.postcode'.tr(),
          hintText: 'address.postcodePlaceholder'.tr(),
          errorText: postcodeError,
        ),
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z ]')),
          LengthLimitingTextInputFormatter(7),
        ],
        onChanged: onPostcodeChanged,
      ),
    );
  }

  Widget _buildHouseNumberField(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'address.houseNumber'.tr(),
      child: TextFormField(
        controller: houseNumberController,
        decoration: InputDecoration(
          labelText: 'address.houseNumber'.tr(),
          hintText: 'address.houseNumberPlaceholder'.tr(),
          errorText: houseNumberError,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(5),
        ],
        onChanged: onHouseNumberChanged,
      ),
    );
  }

  Widget _buildAdditionField(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'address.addition'.tr(),
      child: TextFormField(
        controller: additionController,
        decoration: InputDecoration(
          labelText: 'address.addition'.tr(),
          hintText: 'address.additionPlaceholder'.tr(),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
          LengthLimitingTextInputFormatter(4),
        ],
      ),
    );
  }

  Widget _buildAutoFilledField(
    BuildContext context,
    String label,
    String? value,
  ) {
    final hasValue = value != null && value.isNotEmpty;

    return Semantics(
      textField: true,
      label: label,
      value: hasValue ? value : null,
      child: TextFormField(
        initialValue: value ?? '',
        decoration: InputDecoration(
          labelText: label,
          helperText: hasValue ? 'address.autoFilled'.tr() : null,
          helperStyle: TextStyle(color: DeelmarktColors.success),
          filled: true,
          fillColor:
              hasValue
                  ? DeelmarktColors.successSurface
                  : DeelmarktColors.neutral100,
          suffixIcon:
              isLoading
                  ? const Padding(
                    padding: EdgeInsets.all(Spacing.s3),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  )
                  : null,
        ),
        enabled: false,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color:
              hasValue
                  ? DeelmarktColors.neutral900
                  : DeelmarktColors.neutral500,
        ),
      ),
    );
  }
}

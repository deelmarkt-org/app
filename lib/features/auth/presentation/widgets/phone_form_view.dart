import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/validators.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';

/// Phone number entry form with +31 prefix.
class PhoneFormView extends StatefulWidget {
  const PhoneFormView({
    required this.onSubmit,
    this.isLoading = false,
    this.errorText,
    super.key,
  });

  final ValueChanged<String> onSubmit;
  final bool isLoading;
  final String? errorText;

  @override
  State<PhoneFormView> createState() => _PhoneFormViewState();
}

class _PhoneFormViewState extends State<PhoneFormView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.s6),
          Text(
            'auth.phone_entry_title'.tr(),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.s2),
          Text(
            'auth.phone_entry_subtitle'.tr(),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: Spacing.s6),
          if (widget.errorText != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText!.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DeelmarktColors.error,
                ),
              ),
            ),
            const SizedBox(height: Spacing.s3),
          ],
          DeelInput(
            label: 'form.phone'.tr(),
            hint: '6 12345678',
            controller: _phoneController,
            isRequired: true,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: Validators.dutchPhone,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: Spacing.s3,
                right: Spacing.s1,
              ),
              child: Text('+31', style: theme.textTheme.bodyLarge),
            ),
          ),
          const SizedBox(height: Spacing.s6),
          DeelButton(
            label: 'auth.send_code'.tr(),
            onPressed: widget.isLoading ? null : _submit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}

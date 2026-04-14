/// Extracted sub-widgets and helpers for [AppealScreen].
///
/// Reference: docs/screens/01-auth/07-appeal-form.md
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

const _kErrorGeneric = 'error.generic';

/// Maps a sanction exception to an l10n key for error snackbars.
String appealExceptionToL10nKey(Object error) {
  if (error is AppealWindowExpired) {
    return 'sanction.screen.appeal_window_closed';
  }
  if (error is AppealAlreadyResolved) {
    return 'sanction.screen.appeal_upheld_body';
  }
  return _kErrorGeneric;
}

class AppealSanctionSummaryCard extends StatelessWidget {
  const AppealSanctionSummaryCard({required this.sanction, super.key});

  final SanctionEntity sanction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expiresText =
        sanction.expiresAt != null
            ? DateFormat.yMd().format(sanction.expiresAt!)
            : 'sanction.screen.permanent'.tr();

    return Container(
      padding: const EdgeInsets.all(Spacing.s3),
      decoration: BoxDecoration(
        color:
            isDark ? DeelmarktColors.darkSurface : DeelmarktColors.neutral100,
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'sanction.screen.reason_label'.tr(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color:
                  isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral700,
            ),
          ),
          const SizedBox(height: Spacing.s1),
          Text(sanction.reason, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: Spacing.s3),
          Text(
            'sanction.screen.expires_label'.tr(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color:
                  isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral700,
            ),
          ),
          const SizedBox(height: Spacing.s1),
          Text(expiresText, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: Spacing.s3),
          Text(
            'sanction.screen.sla_72h'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}

class AppealTextField extends StatelessWidget {
  const AppealTextField({
    required this.controller,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'sanction.a11y.appeal_form'.tr(),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        maxLines: null,
        minLines: 6,
        maxLength: 1000,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter:
            (_, {required currentLength, required isFocused, maxLength}) =>
                null,
        decoration: InputDecoration(
          hintText: 'sanction.screen.appeal_hint'.tr(),
          filled: true,
          fillColor:
              isDark
                  ? DeelmarktColors.darkSurfaceElevated
                  : DeelmarktColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DeelmarktRadius.md),
            borderSide: BorderSide(
              color:
                  isDark
                      ? DeelmarktColors.darkBorder
                      : DeelmarktColors.neutral300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DeelmarktRadius.md),
            borderSide: BorderSide(
              color:
                  isDark
                      ? DeelmarktColors.darkBorder
                      : DeelmarktColors.neutral300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DeelmarktRadius.md),
            borderSide: BorderSide(
              color:
                  isDark
                      ? DeelmarktColors.darkPrimary
                      : DeelmarktColors.primary,
              width: 2,
            ),
          ),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class AppealCharCounter extends StatelessWidget {
  const AppealCharCounter({required this.charCount, super.key});

  final int charCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor =
        isDark ? DeelmarktColors.darkError : DeelmarktColors.error;
    final neutralColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;
    final counterColor = charCount < 10 ? errorColor : neutralColor;

    return Semantics(
      liveRegion: true,
      value: '$charCount of 1000 characters',
      excludeSemantics: true,
      child: Text(
        '$charCount / 1000',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: counterColor),
        textAlign: TextAlign.end,
      ),
    );
  }
}

class AppealFormBody extends StatelessWidget {
  const AppealFormBody({
    required this.sanction,
    required this.controller,
    required this.onChanged,
    required this.isSubmitting,
    required this.isValid,
    required this.charCount,
    required this.onSubmit,
    super.key,
  });

  final SanctionEntity sanction;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isSubmitting;
  final bool isValid;
  final int charCount;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.s4),
        AppealSanctionSummaryCard(sanction: sanction),
        const SizedBox(height: Spacing.s4),
        AppealTextField(
          controller: controller,
          onChanged: onChanged,
          enabled: !isSubmitting,
        ),
        const SizedBox(height: Spacing.s2),
        AppealCharCounter(charCount: charCount),
        const SizedBox(height: Spacing.s4),
        DeelButton(
          label: 'sanction.screen.appeal_submit'.tr(),
          isLoading: isSubmitting,
          onPressed: isValid && !isSubmitting ? onSubmit : null,
        ),
        const SizedBox(height: Spacing.s8),
      ],
    );
  }
}

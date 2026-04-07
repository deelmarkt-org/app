import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/details_step/category_selector.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/details_step/condition_selector.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/details_step/shipping_selector.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';
import 'package:deelmarkt/widgets/inputs/deel_postcode_input.dart';
import 'package:deelmarkt/widgets/inputs/deel_price_input.dart';

/// Step 2: Details form for listing creation.
///
/// Contains all listing fields: title, description, category, condition,
/// price, shipping, and location. Validates on user interaction and
/// on "Volgende" tap. Auto-focuses first error field on validation failure.
class DetailsStepView extends ConsumerStatefulWidget {
  const DetailsStepView({super.key});

  @override
  ConsumerState<DetailsStepView> createState() => _DetailsStepViewState();
}

class _DetailsStepViewState extends ConsumerState<DetailsStepView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final DeelPriceController _priceController;
  late final TextEditingController _postcodeController;
  final _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = ref.read(listingCreationNotifierProvider);
    _titleController = TextEditingController(text: state.title);
    _descriptionController = TextEditingController(text: state.description);
    _priceController = DeelPriceController()..valueInCents = state.priceInCents;
    _postcodeController = TextEditingController(text: state.location);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _postcodeController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _syncStateAndAdvance() {
    if (!_formKey.currentState!.validate()) {
      _titleFocus.requestFocus();
      return;
    }

    ref.read(listingCreationNotifierProvider.notifier)
      ..updateTitle(_titleController.text.trim())
      ..updateDescription(_descriptionController.text.trim())
      ..updatePrice(_priceController.valueInCents)
      ..nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingCreationNotifierProvider);
    final notifier = ref.read(listingCreationNotifierProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.s4),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DeelInput(
              controller: _titleController,
              focusNode: _titleFocus,
              label: 'sell.title'.tr(),
              hint: 'sell.titleHint'.tr(),
              maxLength: 60,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'sell.title'.tr()
                          : null,
            ),
            const SizedBox(height: Spacing.s4),
            DeelInput(
              controller: _descriptionController,
              label: 'sell.description'.tr(),
              hint: 'sell.descriptionHint'.tr(),
              maxLines: 5,
              maxLength: 2000,
            ),
            const SizedBox(height: Spacing.s4),
            CategorySelector(
              categoryL1Id: state.categoryL1Id,
              categoryL2Id: state.categoryL2Id,
              onL1Changed: notifier.updateCategoryL1,
              onL2Changed: notifier.updateCategoryL2,
            ),
            const SizedBox(height: Spacing.s4),
            ConditionSelector(
              selected: state.condition,
              onChanged: notifier.updateCondition,
            ),
            const SizedBox(height: Spacing.s4),
            DeelPriceInput(
              controller: _priceController,
              label: 'sell.price'.tr(),
            ),
            const SizedBox(height: Spacing.s4),
            ShippingSelector(
              carrier: state.shippingCarrier,
              weightRange: state.weightRange,
              onCarrierChanged:
                  (c) => notifier.updateShipping(c, state.weightRange),
              onWeightRangeChanged:
                  (w) => notifier.updateShipping(state.shippingCarrier, w),
            ),
            const SizedBox(height: Spacing.s4),
            DeelPostcodeInput(
              controller: _postcodeController,
              label: 'sell.location'.tr(),
              onValidPostcode: notifier.updateLocation,
            ),
            const SizedBox(height: Spacing.s8),
            DeelButton(
              label: 'sell.next'.tr(),
              onPressed: _syncStateAndAdvance,
            ),
            const SizedBox(height: Spacing.s4),
          ],
        ),
      ),
    );
  }
}

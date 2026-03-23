import 'package:easy_localization/easy_localization.dart';

import '../../domain/entities/shipping_label.dart';

/// Presentation-layer extension for localized carrier display names.
///
/// Domain entity stays pure Dart — l10n only in presentation layer.
extension ShippingCarrierExt on ShippingCarrier {
  /// Localized carrier name via l10n keys.
  String get localizedName => switch (this) {
    ShippingCarrier.postnl => 'shipping.carrierPostnl'.tr(),
    ShippingCarrier.dhl => 'shipping.carrierDhl'.tr(),
  };
}

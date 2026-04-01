import 'package:flutter/material.dart';

import 'package:deelmarkt/widgets/trust/trust_banner.dart';

/// Trust banner for escrow protection.
///
/// **Deprecated:** Use [TrustBanner.escrow] directly.
/// This class is retained for backward compatibility and delegates
/// to [TrustBanner.escrow()].
@Deprecated('Use TrustBanner.escrow() instead')
class EscrowTrustBanner extends StatelessWidget {
  const EscrowTrustBanner({this.onMoreInfo, super.key});

  final VoidCallback? onMoreInfo;

  @override
  Widget build(BuildContext context) {
    return TrustBanner.escrow(onMoreInfo: onMoreInfo);
  }
}

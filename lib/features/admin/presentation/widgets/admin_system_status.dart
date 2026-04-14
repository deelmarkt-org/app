import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Static system status card for the admin dashboard sidebar.
///
/// Shows green status dots for core platform services.
/// Phase A: all values are hardcoded as operational.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminSystemStatus extends StatelessWidget {
  const AdminSystemStatus({super.key});

  static const _services = <_ServiceStatus>[
    _ServiceStatus(
      labelKey: 'admin.system.payment_gateway',
      isOperational: true,
    ),
    _ServiceStatus(labelKey: 'admin.system.api_endpoints', isOperational: true),
    _ServiceStatus(labelKey: 'admin.system.mail_server', isOperational: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: DeelmarktColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const SizedBox(height: Spacing.s4),
          ..._services.map(_buildServiceRow),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'admin.system.title'.tr(),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: DeelmarktColors.neutral900,
      ),
    );
  }

  Widget _buildServiceRow(_ServiceStatus service) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
      child: Semantics(
        label:
            '${service.labelKey.tr()}: '
            '${service.isOperational ? 'admin.system.operational'.tr() : 'admin.system.down'.tr()}',
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    service.isOperational
                        ? DeelmarktColors.success
                        : DeelmarktColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Text(
                service.labelKey.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  color: DeelmarktColors.neutral700,
                ),
              ),
            ),
            Text(
              service.isOperational
                  ? 'admin.system.operational'.tr()
                  : 'admin.system.down'.tr(),
              style: TextStyle(
                fontSize: 12,
                color:
                    service.isOperational
                        ? DeelmarktColors.success
                        : DeelmarktColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceStatus {
  const _ServiceStatus({required this.labelKey, required this.isOperational});

  final String labelKey;
  final bool isOperational;
}

/// Suspension gate — blocks all app navigation for active sanctions.
///
/// Shown whenever [activeSanctionProvider] resolves to a non-null
/// [SanctionEntity] with [SanctionEntity.isActive] == true.
/// Back navigation is permanently disabled; the only exit is logout.
///
/// Reference: docs/screens/01-auth/06-suspension-gate.md
library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/services/analytics/sanction_analytics.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/active_sanction_provider.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/suspension_gate_parts.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

const _kLogoutKey = 'auth.logout';

class SuspensionGateScreen extends ConsumerWidget {
  const SuspensionGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sanctionAsync = ref.watch(activeSanctionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fire analytics once per distinct sanction state emission.
    ref.listen<AsyncValue<SanctionEntity?>>(activeSanctionProvider, (
      prev,
      next,
    ) {
      final sanction = next.valueOrNull;
      if (sanction != null && sanction != prev?.valueOrNull) {
        ref
            .read(sanctionAnalyticsProvider)
            .suspensionGateShown(sanctionId: sanction.id, type: sanction.type);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showLogoutConfirm(context, ref);
      },
      child: Scaffold(
        backgroundColor:
            isDark ? DeelmarktColors.darkScaffold : DeelmarktColors.neutral50,
        appBar: _buildAppBar(context, ref),
        body: SafeArea(
          child: ResponsiveBody(
            maxWidth: 480,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s6),
              child: Semantics(
                container: true,
                liveRegion: true,
                child: _buildBody(context, ref, sanctionAsync),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        Semantics(
          button: true,
          label: _kLogoutKey.tr(),
          child: TextButton(
            onPressed: () => _showLogoutConfirm(context, ref),
            child: Text(
              _kLogoutKey.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SanctionEntity?> sanctionAsync,
  ) {
    return sanctionAsync.when(
      loading: _buildLoading,
      error:
          (err, _) => ErrorState(
            onRetry: () => ref.read(activeSanctionProvider.notifier).refresh(),
            message: 'error.generic'.tr(),
          ),
      data: (sanction) {
        if (sanction == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.home);
          });
          return const SizedBox.shrink();
        }
        return SuspensionGateSanctionBody(
          sanction: sanction,
          onContactSupport: () => _launchSupport(context, sanction.id),
        );
      },
    );
  }

  Widget _buildLoading() {
    return SkeletonLoader(
      child: Column(
        children: [
          const SizedBox(height: Spacing.s16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DeelmarktColors.neutral200,
              borderRadius: BorderRadius.circular(DeelmarktRadius.full),
            ),
          ),
          const SizedBox(height: Spacing.s4),
          Container(height: 24, width: 200, color: DeelmarktColors.neutral200),
          const SizedBox(height: Spacing.s4),
          Container(height: 80, color: DeelmarktColors.neutral200),
        ],
      ),
    );
  }

  Future<void> _launchSupport(BuildContext context, String sanctionId) async {
    final uri = 'mailto:support@deelmarkt.com?subject=Sanction%20$sanctionId';
    if (!await launchUrlString(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error.generic'.tr())));
      }
    }
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('auth.logoutConfirmTitle'.tr()),
            content: Text('auth.logoutConfirmBody'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('action.cancel'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(supabaseClientProvider).auth.signOut();
                },
                child: Text('auth.logout'.tr()),
              ),
            ],
          ),
    );
  }
}

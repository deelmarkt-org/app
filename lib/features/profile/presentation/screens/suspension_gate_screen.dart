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
import 'package:url_launcher/url_launcher_string.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/services/analytics/sanction_analytics.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/active_sanction_provider.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/suspension_gate_parts.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
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
            child: _buildResponsiveContent(context, ref, sanctionAsync),
          ),
        ),
      ),
    );
  }

  /// Scrollable gate content. On expanded viewports, wrap in a bordered
  /// Card to match the LoginScreen pattern (focused dialog rather than
  /// bare page). Horizontal margins come from the enclosing [ResponsiveBody]
  /// — the scroll view adds no extra padding on compact so mobile margins
  /// stay at the tokenised `Spacing.screenMarginMobile` (16px). On expanded,
  /// interior padding lives INSIDE the scroll view so the scrollbar sits at
  /// the Card's edge instead of being inset.
  Widget _buildResponsiveContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SanctionEntity?> sanctionAsync,
  ) {
    final body = Semantics(
      container: true,
      liveRegion: true,
      child: _buildBody(context, ref, sanctionAsync),
    );
    if (!Breakpoints.isExpanded(context)) {
      return SingleChildScrollView(child: body);
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.s4),
        child: body,
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
      loading: () => const SuspensionGateLoadingSkeleton(),
      error:
          (err, _) => ErrorState(
            onRetry: () => ref.read(activeSanctionProvider.notifier).refresh(),
            message: 'error.generic'.tr(),
          ),
      data: (sanction) {
        // null means no active sanction — the router redirect (_SanctionRefreshNotifier)
        // will navigate away from /suspended automatically. Show nothing while it fires.
        if (sanction == null) return const SizedBox.shrink();
        return SuspensionGateSanctionBody(
          sanction: sanction,
          onContactSupport: () => _launchSupport(context, sanction.id),
        );
      },
    );
  }

  Future<void> _launchSupport(BuildContext context, String sanctionId) async {
    final uri =
        Uri(
          scheme: 'mailto',
          path: 'support@deelmarkt.com',
          queryParameters: {'subject': 'Sanction $sanctionId'},
        ).toString();
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

/// Appeal form — lets a suspended user submit a written appeal.
///
/// Receives a [SanctionEntity] via [GoRouterState.extra].
/// Draft is auto-saved to SharedPreferences with a 500 ms debounce.
/// Back navigation shows a discard-confirm dialog when the draft is dirty.
///
/// Reference: docs/screens/01-auth/07-appeal-form.md
library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/services/analytics/sanction_analytics.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/appeal_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/appeal_parts.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

part 'appeal_screen.g.dart';

/// Tracks the current appeal body text to drive char-count + submit-button
/// reactivity without setState. Auto-disposed on screen unmount.
@riverpod
class _AppealBody extends _$AppealBody {
  @override
  String build() => '';

  void update(String text) => state = text;
}

class AppealScreen extends ConsumerStatefulWidget {
  const AppealScreen({required this.sanction, super.key});

  final SanctionEntity sanction;

  @override
  ConsumerState<AppealScreen> createState() => _AppealScreenState();
}

class _AppealScreenState extends ConsumerState<AppealScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(sanctionAnalyticsProvider)
          .appealStarted(sanctionId: widget.sanction.id);
      _populateDraft();
    });
  }

  Future<void> _populateDraft() async {
    final draft = await ref
        .read(appealNotifierProvider.notifier)
        .loadDraft(sanctionId: widget.sanction.id);
    if (mounted && draft != null && _controller.text.isEmpty) {
      _controller.text = draft;
      _controller.selection = TextSelection.collapsed(offset: draft.length);
      ref.read(_appealBodyProvider.notifier).update(draft);
    }
  }

  void _onChanged(String text) {
    ref.read(_appealBodyProvider.notifier).update(text);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(appealNotifierProvider.notifier)
          .saveDraft(sanctionId: widget.sanction.id, body: text);
    });
  }

  bool _isBodyValid(String body) =>
      body.trim().length >= 10 && body.length <= 1000;

  Future<void> _submit() async {
    final body = ref.read(_appealBodyProvider);
    if (!_isBodyValid(body)) return;
    await ref
        .read(appealNotifierProvider.notifier)
        .submit(sanctionId: widget.sanction.id, body: body);
  }

  Future<bool> _canPop() async {
    if (ref.read(appealNotifierProvider).isLoading) return false;
    if (ref.read(_appealBodyProvider).trim().isEmpty) return true;
    return _showDiscardDialog();
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('sanction.screen.discard_title'.tr()),
            content: Text('sanction.screen.discard_body'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('sanction.screen.discard_cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'sanction.screen.discard_confirm'.tr(),
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                    color: DeelmarktColors.error,
                  ),
                ),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ref.watch(_appealBodyProvider);
    final notifierState = ref.watch(appealNotifierProvider);
    final isSubmitting = notifierState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<void>>(appealNotifierProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appealExceptionToL10nKey(next.error).tr())),
        );
      }
      if (prev?.isLoading == true && next is AsyncData && context.mounted) {
        context.pop();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final canLeave = await _canPop();
          if (canLeave && context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? DeelmarktColors.darkScaffold : DeelmarktColors.neutral50,
        appBar: _buildAppBar(context, isSubmitting),
        body: SafeArea(
          child: ResponsiveBody(
            maxWidth: 480,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s6),
              child: AppealFormBody(
                sanction: widget.sanction,
                controller: _controller,
                onChanged: _onChanged,
                isSubmitting: isSubmitting,
                isValid: _isBodyValid(body),
                charCount: body.length,
                onSubmit: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isSubmitting) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'action.back'.tr(),
        onPressed:
            isSubmitting
                ? null
                : () async {
                  final canLeave = await _canPop();
                  if (canLeave && context.mounted) context.pop();
                },
      ),
      title: Text('sanction.screen.appeal_title'.tr()),
    );
  }
}

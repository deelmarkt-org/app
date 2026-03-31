import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';

import 'package:deelmarkt/widgets/inputs/deel_input.dart';
import 'package:deelmarkt/widgets/inputs/deel_input_controller_mixin.dart';

/// Search input with debounce, clear button, and optional filter action.
///
/// Composes [DeelInput] with search-specific behaviour:
/// - Magnifying glass prefix icon
/// - Built-in debounce on [onDebouncedChanged]
/// - Clear (X) button when field has content (44x44px touch target)
/// - Optional filter suffix icon
///
/// Reference: docs/design-system/components.md §Inputs (Search)
class DeelSearchInput extends StatefulWidget {
  const DeelSearchInput({
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onDebouncedChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.onFilterTap,
    this.showClearButton = true,
    this.clearTooltip,
    this.filterTooltip,
    this.focusNode,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;

  /// Fires immediately on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Fires after [debounceDuration] of inactivity. Use for API calls.
  final ValueChanged<String>? onDebouncedChanged;

  /// Debounce duration for [onDebouncedChanged]. Defaults to 300ms.
  final Duration debounceDuration;

  /// Callback for the filter icon. If null, no filter icon is shown.
  final VoidCallback? onFilterTap;

  /// Whether to show the clear (X) button when field has content.
  final bool showClearButton;

  /// Localised tooltip for the clear button. Caller provides via l10n.
  final String? clearTooltip;

  /// Localised tooltip for the filter button. Caller provides via l10n.
  final String? filterTooltip;

  final FocusNode? focusNode;
  final bool enabled;

  @override
  State<DeelSearchInput> createState() => _DeelSearchInputState();
}

class _DeelSearchInputState extends State<DeelSearchInput>
    with DeelInputControllerMixin<DeelSearchInput> {
  Timer? _debounceTimer;
  bool _hasContent = false;

  @override
  TextEditingController? get externalController => widget.controller;

  @override
  void initState() {
    super.initState();
    initInputController();
    _hasContent = inputController.text.isNotEmpty;
    inputController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(DeelSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      inputController.removeListener(_onControllerChanged);
      updateInputController(oldWidget.controller);
      inputController.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    inputController.removeListener(_onControllerChanged);
    disposeInputController();
    super.dispose();
  }

  void _onControllerChanged() {
    final hasContent = inputController.text.isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
    }
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    _debounceTimer?.cancel();
    if (widget.onDebouncedChanged != null) {
      _debounceTimer = Timer(widget.debounceDuration, () {
        widget.onDebouncedChanged?.call(value);
      });
    }
  }

  void _handleClear() {
    inputController.clear();
    // Flutter only fires TextFormField.onChanged on user keyboard input,
    // not programmatic controller changes. Explicitly call _handleChanged
    // so onChanged and onDebouncedChanged fire with empty string.
    _handleChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return DeelInput(
      label: widget.label,
      hint: widget.hint,
      controller: inputController,
      focusNode: widget.focusNode,
      onChanged: _handleChanged,
      enabled: widget.enabled,
      textInputAction: TextInputAction.search,
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: Spacing.s3, right: Spacing.s2),
        child: PhosphorIcon(PhosphorIconsRegular.magnifyingGlass, size: 20),
      ),
      suffixIcon: _buildSuffixIcon(),
    );
  }

  Widget? _buildSuffixIcon() {
    final showClear = widget.showClearButton && _hasContent;
    final showFilter = widget.onFilterTap != null;

    if (!showClear && !showFilter) return null;

    // Show both clear + filter when content is present and filter exists.
    // Per components.md §Inputs (Search): 🔍 left, ⚙️ filter right.
    if (showClear && showFilter) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _handleClear,
            icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 20),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: widget.clearTooltip ?? 'input.clear'.tr(),
          ),
          IconButton(
            onPressed: widget.onFilterTap,
            icon: const PhosphorIcon(
              PhosphorIconsRegular.funnelSimple,
              size: 20,
            ),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: widget.filterTooltip ?? 'input.search_filter'.tr(),
          ),
        ],
      );
    }

    if (showClear) {
      return IconButton(
        onPressed: _handleClear,
        icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 20),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        tooltip: widget.clearTooltip ?? 'input.clear'.tr(),
      );
    }

    return IconButton(
      onPressed: widget.onFilterTap,
      icon: const PhosphorIcon(PhosphorIconsRegular.funnelSimple, size: 20),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      tooltip: widget.filterTooltip ?? 'input.search_filter'.tr(),
    );
  }
}

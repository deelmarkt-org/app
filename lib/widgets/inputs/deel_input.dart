import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

import 'package:deelmarkt/widgets/inputs/deel_input_controller_mixin.dart';

/// Base input widget wrapping [TextFormField] with design tokens, WCAG 2.2 AA,
/// and [Form] integration. Composed by [DeelSearchInput], [DeelPriceInput],
/// and [DeelPostcodeInput]. Reference: docs/design-system/components.md §Inputs
const _kDisabledOpacity = 0.4;
const _kMinInputHeight = 52.0;

class DeelInput extends StatefulWidget {
  const DeelInput({
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.textStyle,
    this.obscureText = false,
    this.onFieldSubmitted,
    super.key,
  });

  /// Persistent label above the field. Associated with Semantics.
  /// Must be pre-localised (e.g. `'form.email'.tr()`).
  final String label;

  /// Placeholder text shown when field is empty.
  final String? hint;

  /// Error message shown below the field. Announced via screen reader.
  final String? errorText;

  /// External text controller. If null, one is created internally.
  final TextEditingController? controller;

  /// External focus node. If null, one is created internally.
  final FocusNode? focusNode;

  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final AutovalidateMode? autovalidateMode;

  /// Whether the field accepts input. When false, shows 40% opacity.
  final bool enabled;

  /// Read-only mode: text is selectable but not editable.
  /// Distinct from [enabled] — readOnly still allows focus and copy.
  final bool readOnly;

  /// Marks the field as required: shows `*` and sets Semantics.
  final bool isRequired;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  /// Optional text style override (e.g. tabular figures for price).
  final TextStyle? textStyle;

  /// Whether to obscure the text (for password fields).
  final bool obscureText;

  /// Callback when the user submits the field (e.g. presses Enter/Done).
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<DeelInput> createState() => _DeelInputState();
}

class _DeelInputState extends State<DeelInput>
    with DeelInputControllerMixin<DeelInput> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  TextEditingController? get externalController => widget.controller;

  @override
  void initState() {
    super.initState();
    initInputController();
    _initFocusNode();
  }

  @override
  void didUpdateWidget(DeelInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateInputController(oldWidget.controller);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsFocusNode) _focusNode.dispose();
      _initFocusNode();
    }
  }

  @override
  void dispose() {
    disposeInputController();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelText = widget.isRequired ? '${widget.label} *' : widget.label;

    return Opacity(
      opacity: widget.enabled ? 1.0 : _kDisabledOpacity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _kMinInputHeight),
        child: TextFormField(
          controller: inputController,
          focusNode: _focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
          validator: widget.validator,
          onSaved: widget.onSaved,
          autovalidateMode: widget.autovalidateMode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          obscureText: widget.obscureText,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: widget.textStyle,
          decoration: InputDecoration(
            labelText: labelText,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            fillColor: widget.readOnly ? DeelmarktColors.neutral100 : null,
          ),
        ),
      ),
    );
  }
}

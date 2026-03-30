import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// 6-digit OTP input as individual cells with auto-advance.
///
/// Design: 48x52px cells (WCAG 44x44 minimum), 8px gap.
/// Auto-submits when all 6 digits entered.
/// Supports paste of 6-digit codes and OS SMS autofill.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    required this.onCompleted,
    this.errorText,
    this.semanticLabel,
    super.key,
  });

  final ValueChanged<String> onCompleted;
  final String? errorText;
  final String? semanticLabel;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  static const _digitCount = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final List<FocusNode> _keyListenerFocusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_digitCount, (_) => TextEditingController());
    _focusNodes = List.generate(_digitCount, (_) => FocusNode());
    _keyListenerFocusNodes = List.generate(_digitCount, (_) => FocusNode());
    // Auto-focus first cell after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyListenerFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    // Handle paste: if user pastes 6 digits, fill all cells
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length == _digitCount) {
        _fillAll(digits);
        return;
      }
      // Take only the last digit
      _controllers[index].text = value[value.length - 1];
    }

    if (_controllers[index].text.isNotEmpty && index < _digitCount - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    _checkCompleted();
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _fillAll(String digits) {
    for (var i = 0; i < _digitCount; i++) {
      _controllers[i].text = digits[i];
    }
    _focusNodes[_digitCount - 1].requestFocus();
    _checkCompleted();
  }

  void _checkCompleted() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == _digitCount && RegExp(r'^\d{6}$').hasMatch(code)) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Semantics(
      label: widget.semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_digitCount, (i) {
              return Padding(
                padding: EdgeInsets.only(
                  right: i < _digitCount - 1 ? Spacing.s2 : 0,
                ),
                child: SizedBox(
                  width: 48,
                  height: 52,
                  child: KeyboardListener(
                    focusNode: _keyListenerFocusNodes[i],
                    onKeyEvent: (event) => _onKeyEvent(i, event),
                    child: TextFormField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 2,
                      autofillHints:
                          i == 0 ? const [AutofillHints.oneTimeCode] : null,
                      style: Theme.of(context).textTheme.titleLarge,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            DeelmarktRadius.md,
                          ),
                          borderSide: BorderSide(
                            color:
                                hasError
                                    ? DeelmarktColors.error
                                    : DeelmarktColors.neutral200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            DeelmarktRadius.md,
                          ),
                          borderSide: BorderSide(
                            color:
                                hasError
                                    ? DeelmarktColors.error
                                    : DeelmarktColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onChanged(i, value),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (hasError) ...[
            const SizedBox(height: Spacing.s2),
            Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

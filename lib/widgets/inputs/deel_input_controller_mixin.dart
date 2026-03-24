import 'package:flutter/material.dart';

/// Mixin that manages [TextEditingController] lifecycle for input widgets.
///
/// Handles creation, disposal, and `didUpdateWidget` swapping with ownership
/// tracking. Use in any [State] that wraps a [TextFormField].
///
/// Implementers must override [externalController] to return the widget's
/// controller property.
mixin DeelInputControllerMixin<T extends StatefulWidget> on State<T> {
  late TextEditingController inputController;
  bool _ownsController = false;

  /// Return the widget's optional external [TextEditingController].
  TextEditingController? get externalController;

  /// Initialise the controller. Call from [initState].
  @protected
  void initInputController() {
    if (externalController != null) {
      inputController = externalController!;
      _ownsController = false;
    } else {
      inputController = TextEditingController();
      _ownsController = true;
    }
  }

  /// Handle controller swap on widget rebuild. Call from [didUpdateWidget].
  @protected
  void updateInputController(TextEditingController? oldExternal) {
    if (externalController != oldExternal) {
      if (_ownsController) inputController.dispose();
      initInputController();
    }
  }

  /// Dispose the controller if owned. Call from [dispose].
  @protected
  void disposeInputController() {
    if (_ownsController) inputController.dispose();
  }
}

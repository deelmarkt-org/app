import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/theme.dart';

/// Test helper — wraps an input widget in a themed [MaterialApp].
Widget buildInputApp({
  required Widget child,
  ThemeData? theme,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

/// Wraps an input widget inside a [Form] for integration testing.
Widget buildFormApp({
  required Widget child,
  required GlobalKey<FormState> formKey,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? DeelmarktTheme.light,
    home: Scaffold(
      body: Form(
        key: formKey,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

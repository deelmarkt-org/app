import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/theme.dart';

/// Test helper — wraps a feedback widget in a themed [MaterialApp].
Widget buildFeedbackApp({
  required Widget child,
  ThemeData? theme,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

/// Wraps child in a vertically bounded container for widgets using [Expanded].
Widget buildBoundedFeedbackApp({
  required Widget child,
  ThemeData? theme,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(body: SizedBox(height: 600, child: child)),
    ),
  );
}

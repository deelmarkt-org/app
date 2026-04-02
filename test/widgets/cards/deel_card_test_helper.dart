import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/theme.dart';

/// Test helper — wraps card widgets in a themed [MaterialApp].
Widget buildCardApp({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? DeelmarktTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

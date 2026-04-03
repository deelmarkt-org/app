import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';

/// Test helper — wraps [DeelBadge] or [DeelBadgeRow] in a themed [MaterialApp].
Widget buildBadgeApp({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? DeelmarktTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/theme.dart';

/// Test helper — wraps a [PriceTag] in a themed [MaterialApp].
Widget buildPriceTagApp({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? DeelmarktTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

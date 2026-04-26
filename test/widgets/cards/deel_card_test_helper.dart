import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/theme.dart';

/// Test helper — wraps card widgets in a themed [MaterialApp] inside a
/// [ProviderScope]. The scope is required because some card primitives
/// (e.g. `DeelCardImage` after GH #221) consume Riverpod providers.
Widget buildCardApp({required Widget child, ThemeData? theme}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Test helper — wraps [DeelButton] in a themed [MaterialApp].
Widget buildButtonApp({
  required DeelButton button,
  ThemeData? theme,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

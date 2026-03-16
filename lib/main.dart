import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'core/design_system/theme.dart';
import 'core/l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supportedLocales,
      fallbackLocale: AppLocales.fallbackLocale,
      path: AppLocales.path,
      child: const DeelMarktApp(),
    ),
  );
}

class DeelMarktApp extends StatelessWidget {
  const DeelMarktApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => 'app.name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: DeelmarktTheme.light,
      darkTheme: DeelmarktTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(
        body: Center(child: Text('app.tagline'.tr())),
      ),
    );
  }
}

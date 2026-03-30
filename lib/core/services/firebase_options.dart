// ============================================================================
// PLACEHOLDER — Replace with `flutterfire configure` output.
//
// Steps:
// 1. dart pub global activate flutterfire_cli
// 2. flutterfire configure --project=deelmarkt-xxx
// 3. This file will be overwritten with real Firebase config.
//
// Until then, this stub allows CI builds to compile.
// ============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const _placeholderProjectId = 'deelmarkt-placeholder';
  static const _placeholderSenderId = '000000000000';
  static const _placeholderApiKey = 'placeholder'; // pragma: allowlist secret

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for '
          '$defaultTargetPlatform. Run `flutterfire configure` to generate '
          'platform-specific options.',
        );
    }
  }

  // Placeholder values — app will not connect to Firebase until replaced.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _placeholderApiKey,
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: _placeholderSenderId,
    projectId: _placeholderProjectId,
    authDomain: '$_placeholderProjectId.firebaseapp.com',
    storageBucket: '$_placeholderProjectId.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _placeholderApiKey,
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: _placeholderSenderId,
    projectId: _placeholderProjectId,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _placeholderApiKey,
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: _placeholderSenderId,
    projectId: _placeholderProjectId,
    iosBundleId: 'nl.deelmarkt.deelmarkt',
  );
}

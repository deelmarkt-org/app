import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('android config has correct project values', () {
      final options = DefaultFirebaseOptions.android;
      expect(options.projectId, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
    });

    test('ios config has correct bundle ID', () {
      final options = DefaultFirebaseOptions.ios;
      expect(options.projectId, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.iosBundleId, 'nl.deelmarkt.deelmarkt');
    });

    test('currentPlatform throws on unsupported platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
      });
      expect(
        () => DefaultFirebaseOptions.currentPlatform,
        throwsUnsupportedError,
      );
    });
  });
}

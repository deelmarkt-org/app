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

    test('web config has correct project values', () {
      final options = DefaultFirebaseOptions.web;
      expect(options.projectId, 'deelmarkt-8e696');
      expect(options.appId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
      expect(options.authDomain, contains('deelmarkt'));
      expect(options.measurementId, isNotEmpty);
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

    test('all platforms share the same project ID', () {
      expect(DefaultFirebaseOptions.android.projectId, 'deelmarkt-8e696');
      expect(DefaultFirebaseOptions.ios.projectId, 'deelmarkt-8e696');
      expect(DefaultFirebaseOptions.web.projectId, 'deelmarkt-8e696');
    });
  });
}

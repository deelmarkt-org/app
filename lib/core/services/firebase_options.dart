// Firebase configuration for DeelMarkt — generated from Firebase console.
// Project: deelmarkt-8e696
//
// These are PUBLIC API keys (like Supabase anon key) — safe to commit.
// Private keys (admin SDK) are in firebase/ directory (gitignored).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const _projectId = 'deelmarkt-8e696';
  static const _authDomain = 'deelmarkt-8e696.firebaseapp.com';
  static const _storageBucket = 'deelmarkt-8e696.firebasestorage.app';
  static const _messagingSenderId = '570805600912';

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
          '$defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:
        'AIzaSyB1jlcKv16FQ3uHa_E6NpLf2klM4IFQJ4w', // pragma: allowlist secret
    appId: '1:570805600912:web:4ebb87979bc94e1f444e15',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
    measurementId: 'G-WFL16K5J5Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:
        'AIzaSyAdBHtTbMld3Sx1nfEwylYv2izVQ8vAMvI', // pragma: allowlist secret
    appId: '1:570805600912:android:da2b5812bcc62303444e15',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:
        'AIzaSyDDFpNi788en6aday5klz56JiG_-K0MWsQ', // pragma: allowlist secret
    appId: '1:570805600912:ios:f9d355e2dc5487d4444e15',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'nl.deelmarkt.deelmarkt',
  );
}

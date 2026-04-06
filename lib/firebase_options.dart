// GENERATED FILE - DO NOT EDIT MANUALLY
// Run: flutterfire configure --project=tachtechlabscom --platforms=web
// Requires Firebase Admin permissions (Kyle)
//
// After running flutterfire configure, this file will be overwritten
// with the actual Firebase configuration values.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError('Android not configured - run flutterfire configure');
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured - run flutterfire configure');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS not configured - run flutterfire configure');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows not configured - run flutterfire configure');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured - run flutterfire configure');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  // PLACEHOLDER - Will be replaced by flutterfire configure
  // These values must come from Firebase Console -> Project Settings -> Web App
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER_RUN_FLUTTERFIRE_CONFIGURE',
    appId: 'PLACEHOLDER_RUN_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'tachtechlabscom',
    authDomain: 'tachtechlabscom.firebaseapp.com',
    storageBucket: 'tachtechlabscom.firebasestorage.app',
  );
}

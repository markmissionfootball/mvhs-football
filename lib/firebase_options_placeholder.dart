import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder Firebase configuration.
/// Replace with output from `flutterfire configure` when ready.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder',
    appId: '1:000000000000:android:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'mvhs-football',
    storageBucket: 'mvhs-football.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder',
    appId: '1:000000000000:ios:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'mvhs-football',
    storageBucket: 'mvhs-football.appspot.com',
    iosBundleId: 'com.mvhs.football',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'placeholder',
    appId: '1:000000000000:web:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'mvhs-football',
    storageBucket: 'mvhs-football.appspot.com',
    authDomain: 'mvhs-football.firebaseapp.com',
  );
}

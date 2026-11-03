// Firebase configuration for the "stockinvetory" project.
//
// These are public client identifiers (safe to commit), not secrets.
// Access is controlled by Firestore Security Rules (see firestore.rules).
// Never commit service-account JSON files or private keys.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return web;
      default:
        throw UnsupportedError(
          'This build is configured for Web (Chrome/Edge) and Windows. '
          'Run `flutterfire configure` to add Android/iOS.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC5pHYqCb1JkLoH4TTlicIncRJg8_TiKNc',
    appId: '1:382473729962:web:8fe2a41c4988fbcdfc5dd3',
    messagingSenderId: '382473729962',
    projectId: 'stockinvetory',
    authDomain: 'stockinvetory.firebaseapp.com',
    storageBucket: 'stockinvetory.firebasestorage.app',
    measurementId: 'G-VW2VEBZP5M',
  );
}

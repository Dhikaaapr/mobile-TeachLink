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
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDiUx1NvkC15mE7LD1nptwa4i9J7mUaahs',
    appId: '1:565228537700:android:97b926974a37ae780b5c71',
    messagingSenderId: '565228537700',
    projectId: 'mobile-teachlink',
    authDomain: 'mobile-teachlink.firebaseapp.com',
    storageBucket: 'mobile-teachlink.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDiUx1NvkC15mE7LD1nptwa4i9J7mUaahs',
    appId: '1:565228537700:android:97b926974a37ae780b5c71',
    messagingSenderId: '565228537700',
    projectId: 'mobile-teachlink',
    storageBucket: 'mobile-teachlink.firebasestorage.app',
  );
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDiUx1NvkC15mE7LD1nptwa4i9J7mUaahs',
    appId: '1:565228537700:android:97b926974a37ae780b5c71',
    messagingSenderId: '565228537700',
    projectId: 'mobile-teachlink',
    authDomain: 'mobile-teachlink.firebaseapp.com',
    storageBucket: 'mobile-teachlink.firebasestorage.app',
  );
}

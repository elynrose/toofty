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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAvk3WY4aCdzZX-JCc4HvtsUdRvPRyjlD8',
    appId: '1:550197968686:web:ab66145cf3cf929f7484bf',
    messagingSenderId: '550197968686',
    projectId: 'todoos-briktap',
    authDomain: 'todoos-briktap.firebaseapp.com',
    storageBucket: 'todoos-briktap.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjH1Wk7WrT9Su0DyiBUTgy4h4gylVkpIY',
    appId: '1:550197968686:android:3b714c5c8cd8a26d7484bf',
    messagingSenderId: '550197968686',
    projectId: 'todoos-briktap',
    storageBucket: 'todoos-briktap.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAx26957HD7XIoHEQgBbZnhv-tmmuMn9NY',
    appId: '1:550197968686:ios:822da0d048f8a0797484bf',
    messagingSenderId: '550197968686',
    projectId: 'todoos-briktap',
    storageBucket: 'todoos-briktap.firebasestorage.app',
    iosBundleId: 'com.briktap.toofty',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAx26957HD7XIoHEQgBbZnhv-tmmuMn9NY',
    appId: '1:550197968686:ios:822da0d048f8a0797484bf',
    messagingSenderId: '550197968686',
    projectId: 'todoos-briktap',
    storageBucket: 'todoos-briktap.firebasestorage.app',
    iosBundleId: 'com.briktap.toofty',
  );
}

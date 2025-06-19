// ignore_for_file: type=lint
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDgGtrW7zCMa36n83_e-6fjSP9QhkCni3k',
    appId: '1:399976911903:web:8ca40c5ba45b3993a9712a',
    messagingSenderId: '399976911903',
    projectId: 'fir-flutter-auth-6fb90',
    authDomain: 'fir-flutter-auth-6fb90.firebaseapp.com',
    storageBucket: 'fir-flutter-auth-6fb90.firebasestorage.app',
    measurementId: 'G-3XY7H7N3Q6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgXY7qSdLrN9ZqJnzhURR_EbzL2JrwZ9g',
    appId: '1:399976911903:android:552a547c2d036d35a9712a',
    messagingSenderId: '399976911903',
    projectId: 'fir-flutter-auth-6fb90',
    storageBucket: 'fir-flutter-auth-6fb90.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCpeFWt1NIonQJNK7h1pltDALy5WTpp7fI',
    appId: '1:399976911903:ios:92b4b2aa2964491aa9712a',
    messagingSenderId: '399976911903',
    projectId: 'fir-flutter-auth-6fb90',
    storageBucket: 'fir-flutter-auth-6fb90.firebasestorage.app',
    iosClientId: '399976911903-r0kp22jh05gdnus7jlj5hoac9q0vb9s9.apps.googleusercontent.com',
    iosBundleId: 'com.example.singupLogin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCpeFWt1NIonQJNK7h1pltDALy5WTpp7fI',
    appId: '1:399976911903:ios:92b4b2aa2964491aa9712a',
    messagingSenderId: '399976911903',
    projectId: 'fir-flutter-auth-6fb90',
    storageBucket: 'fir-flutter-auth-6fb90.firebasestorage.app',
    iosClientId: '399976911903-r0kp22jh05gdnus7jlj5hoac9q0vb9s9.apps.googleusercontent.com',
    iosBundleId: 'com.example.singupLogin',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDgGtrW7zCMa36n83_e-6fjSP9QhkCni3k',
    appId: '1:399976911903:web:08bee114744b02b4a9712a',
    messagingSenderId: '399976911903',
    projectId: 'fir-flutter-auth-6fb90',
    authDomain: 'fir-flutter-auth-6fb90.firebaseapp.com',
    storageBucket: 'fir-flutter-auth-6fb90.firebasestorage.app',
    measurementId: 'G-PPRDEPQMDH',
  );
}
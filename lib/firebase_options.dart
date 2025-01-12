// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyBggNe6Z9vk-kRGf6TXtvtnh-UZCJxKAsI',
    appId: '1:489153684515:web:185542e222804f21fe3d96',
    messagingSenderId: '489153684515',
    projectId: 'little-strategy-6837a',
    authDomain: 'little-strategy-6837a.firebaseapp.com',
    databaseURL:
        'https://little-strategy-6837a-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'little-strategy-6837a.firebasestorage.app',
    measurementId: 'G-PGYEQ3HF38',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyByBjOSUKP_UenH0lJT_Vm1dShcOIUASWE',
    appId: '1:489153684515:android:a96b9b8fe4cf52e4fe3d96',
    messagingSenderId: '489153684515',
    projectId: 'little-strategy-6837a',
    databaseURL:
        'https://little-strategy-6837a-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'little-strategy-6837a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvGQGrmgjZoCa1ZRSKHdiuNawohHL0P7w',
    appId: '1:489153684515:ios:57488f5461cdd3a6fe3d96',
    messagingSenderId: '489153684515',
    projectId: 'little-strategy-6837a',
    databaseURL:
        'https://little-strategy-6837a-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'little-strategy-6837a.firebasestorage.app',
    iosClientId:
        '489153684515-vn4ro1356rlntfl7kpialek21u4e3cac.apps.googleusercontent.com',
    iosBundleId: 'com.example.rndGame',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDvGQGrmgjZoCa1ZRSKHdiuNawohHL0P7w',
    appId: '1:489153684515:ios:57488f5461cdd3a6fe3d96',
    messagingSenderId: '489153684515',
    projectId: 'little-strategy-6837a',
    databaseURL:
        'https://little-strategy-6837a-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'little-strategy-6837a.firebasestorage.app',
    iosClientId:
        '489153684515-vn4ro1356rlntfl7kpialek21u4e3cac.apps.googleusercontent.com',
    iosBundleId: 'com.example.rndGame',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB__8S7R0bZZEbwoSPDdbvUeiAVKhy34bg',
    appId: '1:489153684515:web:78d5ad892ad11f9ffe3d96',
    messagingSenderId: '489153684515',
    projectId: 'little-strategy-6837a',
    authDomain: 'little-strategy-6837a.firebaseapp.com',
    databaseURL:
        'https://little-strategy-6837a-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'little-strategy-6837a.firebasestorage.app',
    measurementId: 'G-ZLSHE7SV0N',
  );
}

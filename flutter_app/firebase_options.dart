// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDClnqBlAkRRRk7MbUOraP5QTxbHuuBuco',
    appId: '1:429736406681:web:f97549da6f866af0bd1208',
    messagingSenderId: '429736406681',
    projectId: 'smart-alarm-clock-poc-2a0c4',
    authDomain: 'smart-alarm-clock-poc-2a0c4.firebaseapp.com',
    storageBucket: 'smart-alarm-clock-poc-2a0c4.appspot.com',
    databaseURL: 'https://smart-alarm-clock-poc-2a0c4-default-rtdb.europe-west1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADyZmJvoMKtu8CO6LKOKlI4vlzAt9YXss',
    appId: '1:429736406681:android:f77c0ba8419ea15bbd1208',
    messagingSenderId: '429736406681',
    projectId: 'smart-alarm-clock-poc-2a0c4',
    storageBucket: 'smart-alarm-clock-poc-2a0c4.appspot.com',
    databaseURL: 'https://smartalarmclock-c5a5d-default-rtdb.europe-west1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2z1U3XGqrfKu8HEJfuyhDcLApHMe4zOw',
    appId: '1:429736406681:ios:dc7fdf9012122272bd1208',
    messagingSenderId: '429736406681',
    projectId: 'smart-alarm-clock-poc-2a0c4',
    storageBucket: 'smart-alarm-clock-poc-2a0c4.appspot.com',
    iosBundleId: 'com.example.smartAlarmClockPoc',
    databaseURL: 'https://smart-alarm-clock-poc-2a0c4-default-rtdb.europe-west1.firebasedatabase.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB2z1U3XGqrfKu8HEJfuyhDcLApHMe4zOw',
    appId: '1:429736406681:ios:88617ad38c8ee2ccbd1208',
    messagingSenderId: '429736406681',
    projectId: 'smart-alarm-clock-poc-2a0c4',
    storageBucket: 'smart-alarm-clock-poc-2a0c4.appspot.com',
    iosBundleId: 'com.example.smartAlarmClockPoc.RunnerTests',
    databaseURL: 'https://smart-alarm-clock-poc-2a0c4-default-rtdb.europe-west1.firebasedatabase.app',

  );
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMnAZS1QKWWK_hbXOTN-k7-fuvf9oQKh4',
    appId: '1:475028356738:android:111e8f4e7713f09a967e9b',
    messagingSenderId: '475028356738',
    projectId: 'binova-92083',
    storageBucket: 'binova-92083.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Firebase is configured only for Android.');
  }
}

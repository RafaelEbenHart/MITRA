import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Isikan data Firebase masing-masing (project Anda) di sini.
// Dapat di-copy dari Firebase Console > Project settings > Your apps.

class FirebaseCustomOptions {
  static FirebaseOptions get android => const FirebaseOptions(
        apiKey: 'AIzaSyD5gtwEJsc-OwVibClHd2gTCkQ5Rsh4RgU',
        appId: '1:77189856963:android:976e3bcf68220f0b41ac76',
        messagingSenderId: '77189856963',
        projectId: 'testproj-46c89',
        storageBucket: 'testproj-46c89.firebasestorage.app',
      );

  static FirebaseOptions get web => const FirebaseOptions(
        apiKey: 'AIzaSyD5gtwEJsc-OwVibClHd2gTCkQ5Rsh4RgU',
        appId: '1:77189856963:web:976e3bcf68220f0b41ac76',
        messagingSenderId: '77189856963',
        projectId: 'testproj-46c89',
        authDomain: 'testproj-46c89.firebaseapp.com',
        storageBucket: 'testproj-46c89.firebasestorage.app',
        measurementId: 'G-XXXXXXXXXX',
      );

  static FirebaseOptions get ios => const FirebaseOptions(
        apiKey: 'AIzaSyD5gtwEJsc-OwVibClHd2gTCkQ5Rsh4RgU',
        appId: '1:77189856963:ios:976e3bcf68220f0b41ac76',
        messagingSenderId: '77189856963',
        projectId: 'testproj-46c89',
        storageBucket: 'testproj-46c89.firebasestorage.app',
      );

  static FirebaseOptions get options {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;

    // fallback
    return android;
  }
}

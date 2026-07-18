import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions belum dikonfigurasi untuk platform selain Android.',
    );
  }

  // SILAHKAN GANTI STRING DI BAWAH INI DENGAN DATA DARI FIREBASE CONSOLE BAPAK
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA123456789...Isi_API_Key_Bapak...',
    appId: '1:1234567890:android:abcdef123456...',
    messagingSenderId: '1234567890',
    projectId: 'putra-surabaya-pos', // Contoh id proyek
    storageBucket: 'putra-surabaya-pos.firebasestorage.app', // atau .appspot.com untuk proyek lama
  );
}

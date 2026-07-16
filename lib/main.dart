import 'package:flutter/material.dart'; // <-- HANYA butuh ini saja untuk tes

void main() async {
  // 1. Amankan inisialisasi native di awal
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Aktifkan penangkap error layar merah
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            "Aplikasi Berhasil Terbuka!\n(Database & POS Aman)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}

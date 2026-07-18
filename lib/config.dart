Import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  static const String fontFamily = 'Poppins';

  // ==========================================
  // PALET BLENDED BRIGHT TEAL & GOLD
  // ==========================================
  static const Color brightTeal = Color(0xFF00D2C4);       // Biru Kehijauan Terang/Cyan POS
  static const Color mintIceWhite = Color(0xFFE6F9F8);     // Putih kebiruan-hijau sangat muda (Es)
  static const Color goldSoft = Color(0xFFE8C887);         // Emas lembut untuk penyeimbang hangat
  
  // Teks khusus untuk background terang (Kontras Tinggi)
  static const Color textDarkTeal = Color(0xFF062F2C);     // Hijau-Biru gelap pekat (Pengganti hitam)
  static const Color textSecondary = Color(0xFF4A6B68);    // Abu-abu kehijauan untuk sub-informasi

  // Gradasi Melebur 3 Warna: Emas -> Putih Es -> Biru Kehijauan Terang
  static const Gradient blendedTealTriple = LinearGradient(
    colors: [
      goldSoft,
      mintIceWhite,
      brightTeal,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: mintIceWhite, // Menggunakan putih es sebagai latar dasar aplikasi
      colorScheme: const ColorScheme.light(
        primary: brightTeal,
        secondary: goldSoft,
        surface: Colors.white,
      ),
    );
  }
}

class FluidMeshBackground extends StatelessWidget {
  final Widget child;

  const FluidMeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Warna Dasar Paling Belakang (Cream White)
        Container(color: const Color(0xFFFFFDF9)),

        // 2. Blob Warna Emas (Top Left menuju Tengah)
        Positioned(
          top: -100,
          left: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFEAD09D).withOpacity(0.8),
                  const Color(0xFFEAD09D).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // 3. Blob Warna Biru Muda/Cyan (Tengah ke Kanan)
        Positioned(
          top: 150,
          right: -100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB9D7EA).withOpacity(0.85),
                  const Color(0xFFB9D7EA).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // 4. Blob Warna Ungu Lavender / Lilac (Kiri Bawah)
        Positioned(
          bottom: -50,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD6C7E8).withOpacity(0.8),
                  const Color(0xFFD6C7E8).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // 5. KUNCI UTAMA: Lapisan Pelebur Efek Cair (High Blur Filter)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70.0, sigmaY: 70.0),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 6. Lapisan Interface Aplikasi di Atasnya
        SafeArea(child: child),
      ],
    );
  }
}


class GoldenGreenTheme {
  // 1. DEFINISI WARNA SESUAI PROPORSI
  static const Color dominantGold = Color(0xFFDFB76C);    // 65% Dominan
  static const Color greenGold = Color(0xFF9FA872);       // 25% Aksen Hijau Emas
  static const Color brightHighlight = Color(0xFFFFF9E6); // 10% Kilau Terang (Ivory Bright)
  
  // Teks Kontras Tinggi Khusus Tema Emas
  static const Color textEspresso = Color(0xFF2A1E17);     // Cokelat kopi pekat untuk teks utama
  static const Color textSubdued = Color(0xFF5C5045);      // Untuk teks sekunder/keterangan

  /// Widget Background Mesh Cair dengan proporsi 65-25-10
  static Widget buildFluidBackground({required Widget child}) {
    return Stack(
      children: [
        // A. KANVAS UTAMA (65% Dominasi Emas)
        Container(color: dominantGold),

        // B. BLOB HIJAU EMAS (Mengambil porsi ~25% di sudut layar)
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  greenGold.withOpacity(0.9),
                  greenGold.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // C. BLOB BRIGHT HIGHLIGHT (10% Kilau Titik Temu di bagian atas)
        Positioned(
          top: 40,
          left: 20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  brightHighlight.withOpacity(0.95),
                  brightHighlight.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // D. FILTER BLUR EKSTREM (Menyatukan seluruh blob secara organik)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
            child: Container(color: Colors.transparent),
          ),
        ),

        // E. LAYER KONTEN APLIKASI
        SafeArea(child: child),
      ],
    );
  }
}
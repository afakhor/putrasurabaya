import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class AppTheme {
  final String name;
  final ThemeData themeData;
  final Widget Function({required Widget child}) backgroundBuilder;
  final Color statusBarColor;

  const AppTheme({
    required this.name,
    required this.themeData,
    required this.backgroundBuilder,
    required this.statusBarColor,
  });
}

// ================== HELPER ANIMATED BLOB ==================
class _AnimatedBlob extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  const _AnimatedBlob({required this.size, required this.color, required this.duration});

  @override
  State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.scale(
        scale: 1 + (_controller.value * 0.15),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [widget.color, widget.color.withOpacity(0)]),
          ),
        ),
      ),
    );
  }
}

// ================== KUMPULAN SEMUA TEMA ==================
class AppThemes {
  // --- TEMA LAMA (VERSI CANTIK) ---
  static const Color brightTeal = Color(0xFF00D2C4);
  static const Color mintIceWhite = Color(0xFFE6F9F8);
  static const Color goldSoft = Color(0xFFE8C887);

  static final blendedBright = AppTheme(
    name: 'Blended Bright',
    statusBarColor: Colors.transparent,
    themeData: ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(primary: brightTeal, secondary: goldSoft, surface: Colors.white),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Color(0xFF062F2C)),
    ),
    backgroundBuilder: ({required child}) => _BlendedBrightBackground(child: child),
  );

  static final goldenGreen = AppTheme(
    name: 'Golden Hour',
    statusBarColor: Colors.transparent,
    themeData: ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(primary: Color(0xFFDFB76C), secondary: Color(0xFF9FA872), surface: Colors.white),
    ),
    backgroundBuilder: ({required child}) => _GoldenGreenBackground(child: child),
  );

  // --- TEMA VIRAL BARU ---

  // 1. Viral 2026: Aurora Borealis - paling populer di Dribbble
  static final aurora = AppTheme(
    name: 'Aurora',
    statusBarColor: Colors.transparent,
    themeData: ThemeData(useMaterial3: true, fontFamily: 'Poppins', scaffoldBackgroundColor: Colors.transparent, colorScheme: ColorScheme.light(primary: Color(0xFF7C3AED), secondary: Color(0xFF06B6D4), surface: Colors.white)),
    backgroundBuilder: ({required child}) => _MeshWrapper(
      baseColor: const Color(0xFF0F172A),
      blobs: const [
        _BlobData(top: -100, left: -80, size: 500, color: Color(0xFF7C3AED)),
        _BlobData(top: 100, right: -100, size: 450, color: Color(0xFF06B6D4)),
        _BlobData(bottom: -80, left: 20, size: 500, color: Color(0xFFEC4899)),
      ],
      child: child,
    ),
  );

  // 2. Viral: Sunset Sorbet - Peach Fuzz Pantone
  static final sunsetSorbet = AppTheme(
    name: 'Sunset Sorbet',
    statusBarColor: Colors.transparent,
    themeData: ThemeData(useMaterial3: true, fontFamily: 'Poppins', scaffoldBackgroundColor: Colors.transparent),
    backgroundBuilder: ({required child}) => _MeshWrapper(
      baseColor: const Color(0xFFFFF7ED),
      blobs: const [
        _BlobData(top: -120, left: -50, size: 450, color: Color(0xFFFF8A65)),
        _BlobData(top: 200, right: -80, size: 400, color: Color(0xFFFFB74D)),
        _BlobData(bottom: -100, left: -50, size: 450, color: Color(0xFFF48FB1)),
      ],
      child: child,
    ),
  );

  // 3. Viral: Midnight Galaxy
  static final midnight = AppTheme(
    name: 'Midnight Galaxy',
    statusBarColor: Colors.transparent,
    themeData: ThemeData(useMaterial3: true, fontFamily: 'Poppins', scaffoldBackgroundColor: Colors.transparent, brightness: Brightness.dark),
    backgroundBuilder: ({required child}) => _MeshWrapper(
      baseColor: const Color(0xFF020617),
      blobs: const [
        _BlobData(top: -100, left: -100, size: 500, color: Color(0xFF1E3A8A)),
        _BlobData(bottom: -120, right: -80, size: 550, color: Color(0xFF581C87)),
        _BlobData(top: 300, left: 50, size: 300, color: Color(0xFF0E7490)),
      ],
      child: child,
    ),
  );

  // 4. Viral: Sakura Blush - cewek banget, clean girl aesthetic
  static final sakura = AppTheme(
    name: 'Sakura Blush',
    statusBarColor: Colors.transparent,
    themeData: ThemeData(useMaterial3: true, fontFamily: 'Poppins', scaffoldBackgroundColor: Colors.transparent),
    backgroundBuilder: ({required child}) => _MeshWrapper(
      baseColor: const Color(0xFFFFF1F2),
      blobs: const [
        _BlobData(top: -80, left: -60, size: 400, color: Color(0xFFFDA4AF)),
        _BlobData(top: 150, right: -60, size: 380, color: Color(0xFFF0ABFC)),
        _BlobData(bottom: -80, left: -20, size: 450, color: Color(0xFFBAE6FD)),
      ],
      child: child,
    ),
  );

  // 5. Viral 2025: Mocha Mousse - Color of the Year Pantone
  static final mocha = AppTheme(
    name: 'Mocha Mousse',
    statusBarColor: Colors.transparent,
    themeData: ThemeData(useMaterial3: true, fontFamily: 'Poppins', scaffoldBackgroundColor: Colors.transparent),
    backgroundBuilder: ({required child}) => _MeshWrapper(
      baseColor: const Color(0xFFEFEBE9),
      blobs: const [
        _BlobData(top: -100, left: -80, size: 450, color: Color(0xFFA18072)),
        _BlobData(bottom: -80, right: -80, size: 400, color: Color(0xFFD7CCC8)),
        _BlobData(top: 200, left: 100, size: 250, color: Color(0xFFFFCC80)),
      ],
      child: child,
    ),
  );

  // LIST SEMUA TEMA - INI YANG DI RANDOM
  static List<AppTheme> get allThemes => [
        blendedBright,
        goldenGreen,
        aurora,
        sunsetSorbet,
        midnight,
        sakura,
        mocha,
      ];
}

// ================== IMPLEMENTASI BACKGROUND LAMA (DIPERCANTIK) ==================
class _BlendedBrightBackground extends StatelessWidget {
  final Widget child;
  const _BlendedBrightBackground({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(color: const Color(0xFFFFFDF9)),
      Positioned(top: -100, left: -50, child: _AnimatedBlob(size: 400, color: const Color(0xFFEAD09D).withOpacity(0.9), duration: const Duration(seconds: 6))),
      Positioned(top: 150, right: -100, child: _AnimatedBlob(size: 450, color: const Color(0xFFB9D7EA).withOpacity(0.9), duration: const Duration(seconds: 8))),
      Positioned(bottom: -50, left: -100, child: _AnimatedBlob(size: 400, color: const Color(0xFFD6C7E8).withOpacity(0.9), duration: const Duration(seconds: 7))),
      Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: Container(color: Colors.white.withOpacity(0.15)))),
      SafeArea(child: child),
    ]);
  }
}

class _GoldenGreenBackground extends StatelessWidget {
  final Widget child;
  const _GoldenGreenBackground({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(color: const Color(0xFFDFB76C)),
      Positioned(bottom: -50, right: -50, child: _AnimatedBlob(size: 380, color: const Color(0xFF9FA872), duration: const Duration(seconds: 5))),
      Positioned(top: 40, left: 20, child: _AnimatedBlob(size: 200, color: const Color(0xFFFFF9E6), duration: const Duration(seconds: 4))),
      Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(color: Colors.transparent))),
      SafeArea(child: child),
    ]);
  }
}

// Generic Wrapper untuk tema baru biar rapi
class _BlobData {
  final double? top, bottom, left, right, size;
  final Color color;
  const _BlobData({this.top, this.bottom, this.left, this.right, required this.size, required this.color});
}
class _MeshWrapper extends StatelessWidget {
  final Color baseColor;
  final List<_BlobData> blobs;
  final Widget child;
  const _MeshWrapper({required this.baseColor, required this.blobs, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(color: baseColor),
      ...blobs.map((b) => Positioned(
        top: b.top, bottom: b.bottom, left: b.left, right: b.right,
        child: _AnimatedBlob(size: b.size!, color: b.color, duration: Duration(seconds: 5 + math.Random().nextInt(4))),
      )),
      Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))),
      SafeArea(child: child),
    ]);
  }
}
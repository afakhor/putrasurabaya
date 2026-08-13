import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  final String name;
  final ThemeData themeData;
  final Widget Function({required Widget child}) backgroundBuilder;
  const AppTheme({required this.name, required this.themeData, required this.backgroundBuilder});
}

// ===== WIDGET ANTI BUTA - PAKAI INI KALAU TEXT DI LUAR GLASSCARD =====
class ContrastText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  const ContrastText(this.data, {super.key, this.style});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? Colors.white : const Color(0xFF1A1C1E);
    final outline = isDark ? Colors.black : Colors.white;
    return Stack(children: [
      Text(data, style: style?.copyWith(foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5..color = outline)),
      Text(data, style: style?.copyWith(color: fill)),
    ]);
  }
}

// ===== GLASS CARD FIX TOTAL =====
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final VoidCallback? onTap;
  const GlassCard({super.key, required this.child, this.padding, this.radius = 20, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);

    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                  ? const Color(0xFF1E293B).withValues(alpha: 0.70) 
                  : Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.07),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              // FIX: Pakai DefaultTextStyle biasa, bukan merge, biar paksa warna solid
              child: DefaultTextStyle(
                style: TextStyle(color: textColor, fontSize: 14),
                child: IconTheme(
                  data: IconThemeData(color: textColor),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBlob extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  const _AnimatedBlob({required this.size, required this.color, required this.duration});
  @override State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState(){ super.initState(); _c = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true); }
  @override void dispose(){ _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    return AnimatedBuilder(
      animation: _c, 
      builder: (_, __) => Transform.scale(
        scale: 1 + (_c.value * 0.18),
        child: Container(
          width: widget.size, height: widget.size, 
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [widget.color, widget.color.withValues(alpha: 0)])),
        ),
      ),
    );
  }
}

class _BlobData {
  final double? top, bottom, left, right; 
  final double size; 
  final Color color;
  const _BlobData({this.top, this.bottom, this.left, this.right, required this.size, required this.color});
}

class _MeshWrapper extends StatelessWidget {
  final Color baseColor; 
  final List<_BlobData> blobs; 
  final Widget child;
  const _MeshWrapper({required this.baseColor, required this.blobs, required this.child});

  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: [
      Container(color: baseColor),
      ...blobs.map((b) => Positioned(
        top: b.top, bottom: b.bottom, left: b.left, right: b.right, 
        child: _AnimatedBlob(size: b.size, color: b.color, duration: Duration(seconds: 6 + (b.size.toInt() % 4))),
      )),
      // FIX: Blur turun dari 80 ke 45 biar gak lag
      Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45), child: Container(color: Colors.transparent))),
      // FIX KUNCI: Scrim kuat biar blob jreng jadi pucat
      Positioned.fill(child: Container(color: isDark ? Colors.black.withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.72))),
      child,
    ]);
  }
}

class AppThemes {
  static ThemeData _baseTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    final base = ThemeData(brightness: b, useMaterial3: true);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1C1E);

    // FIX TOTAL: Paksa semua text minimal 14px
    TextTheme t = GoogleFonts.poppinsTextTheme(base.textTheme);
    t = t.copyWith(
      displayLarge: t.displayLarge!.copyWith(fontSize: 57, color: textColor),
      displayMedium: t.displayMedium!.copyWith(fontSize: 45, color: textColor),
      displaySmall: t.displaySmall!.copyWith(fontSize: 36, color: textColor),
      headlineLarge: t.headlineLarge!.copyWith(fontSize: 32, color: textColor),
      headlineMedium: t.headlineMedium!.copyWith(fontSize: 28, color: textColor),
      headlineSmall: t.headlineSmall!.copyWith(fontSize: 24, color: textColor),
      titleLarge: t.titleLarge!.copyWith(fontSize: 22, color: textColor),
      titleMedium: t.titleMedium!.copyWith(fontSize: 16, color: textColor),
      titleSmall: t.titleSmall!.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: t.bodyLarge!.copyWith(fontSize: 16, color: textColor),
      bodyMedium: t.bodyMedium!.copyWith(fontSize: 14, color: textColor),
      bodySmall: t.bodySmall!.copyWith(fontSize: 14, color: textColor), // DULU 12 -> SEKARANG 14
      labelLarge: t.labelLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: t.labelMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: textColor), // DULU 12 -> 14
      labelSmall: t.labelSmall!.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3, color: textColor), // DULU 11 -> 14
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(seedColor: isDark ? const Color(0xFF7C3AED) : const Color(0xFF00BFA6), brightness: b),
      textTheme: t,
      primaryTextTheme: t,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.poppins(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: textColor),
      listTileTheme: ListTileThemeData(iconColor: textColor, textColor: textColor),
    );
  }

  static final blendedBright = AppTheme(name: 'Blended Bright Teal', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => Stack(children: [ Container(color: const Color(0xFFFFFDF9)), Positioned(top: -100, left: -50, child: _AnimatedBlob(size: 400, color: const Color(0xFFEAD09D).withValues(alpha: 0.9), duration: const Duration(seconds: 6))), Positioned(top: 150, right: -100, child: _AnimatedBlob(size: 450, color: const Color(0xFFB9D7EA).withValues(alpha: 0.9), duration: const Duration(seconds: 8))), Positioned(bottom: -50, left: -100, child: _AnimatedBlob(size: 400, color: const Color(0xFFD6C7E8).withValues(alpha: 0.9), duration: const Duration(seconds: 7))), Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45), child: Container(color: Colors.transparent))), Positioned.fill(child: Container(color: Colors.white.withValues(alpha: 0.72))), SafeArea(child: child), ]));
  static final goldenGreen = AppTheme(name: 'Golden Hour', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => Stack(children: [ Container(color: const Color(0xFFDFB76C)), Positioned(bottom: -50, right: -50, child: _AnimatedBlob(size: 380, color: const Color(0xFF9FA872), duration: const Duration(seconds: 5))), Positioned(top: 40, left: 20, child: _AnimatedBlob(size: 200, color: const Color(0xFFFFF9E6), duration: const Duration(seconds: 4))), Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45), child: Container(color: Colors.transparent))), Positioned.fill(child: Container(color: Colors.white.withValues(alpha: 0.72))), SafeArea(child: child), ]));
  static final aurora = AppTheme(name: 'Aurora Borealis', themeData: _baseTheme(Brightness.dark), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFF0F172A), blobs: const [_BlobData(top: -100, left: -80, size: 500, color: Color(0xFF7C3AED)), _BlobData(top: 100, right: -100, size: 450, color: Color(0xFF06B6D4)), _BlobData(bottom: -80, left: 20, size: 500, color: Color(0xFFEC4899))], child: SafeArea(child: child)));
  static final sunset = AppTheme(name: 'Sunset Sorbet', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFFFF7ED), blobs: const [_BlobData(top: -120, left: -50, size: 450, color: Color(0xFFFF8A65)), _BlobData(top: 200, right: -80, size: 400, color: Color(0xFFFFB74D)), _BlobData(bottom: -100, left: -50, size: 450, color: Color(0xFFF48FB1))], child: SafeArea(child: child)));
  static final midnight = AppTheme(name: 'Midnight Galaxy', themeData: _baseTheme(Brightness.dark), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFF020617), blobs: const [_BlobData(top: -100, left: -100, size: 500, color: Color(0xFF1E3A8A)), _BlobData(bottom: -120, right: -80, size: 550, color: Color(0xFF581C87)), _BlobData(top: 300, left: 50, size: 300, color: Color(0xFF0E7490))], child: SafeArea(child: child)));
  static final sakura = AppTheme(name: 'Sakura Blush', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFFFF1F2), blobs: const [_BlobData(top: -80, left: -60, size: 400, color: Color(0xFFFDA4AF)), _BlobData(top: 150, right: -60, size: 380, color: Color(0xFFF0ABFC)), _BlobData(bottom: -80, left: -20, size: 450, color: Color(0xFFBAE6FD))], child: SafeArea(child: child)));
  static final mocha = AppTheme(name: 'Mocha Mousse', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFEFEBE9), blobs: const [_BlobData(top: -100, left: -80, size: 450, color: Color(0xFFA18072)), _BlobData(bottom: -80, right: -80, size: 400, color: Color(0xFFD7CCC8)), _BlobData(top: 200, left: 100, size: 250, color: Color(0xFFFFCC80))], child: SafeArea(child: child)));
  static final liquidGlass = AppTheme(name: 'Liquid Glass iOS 26', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFF8FAFC), blobs: const [_BlobData(top: -120, left: -100, size: 500, color: Color(0xFF38BDF8)), _BlobData(top: 0, right: -120, size: 480, color: Color(0xFFA78BFA)), _BlobData(bottom: -120, left: 0, size: 550, color: Color(0xFFFB7185))], child: SafeArea(child: child)));
  static final matchaLatte = AppTheme(name: 'Matcha Latte', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFF1F8E9), blobs: const [_BlobData(top: -80, left: -60, size: 420, color: Color(0xFFAED581)), _BlobData(bottom: -100, right: -60, size: 460, color: Color(0xFF8D6E63)), _BlobData(top: 250, right: 20, size: 220, color: Color(0xFFFFF9C4))], child: SafeArea(child: child)));
  static final barbieCore = AppTheme(name: 'Barbiecore', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFFFF0F6), blobs: const [_BlobData(top: -100, left: -70, size: 450, color: Color(0xFFFF1493)), _BlobData(bottom: -90, right: -70, size: 480, color: Color(0xFFDA70D6)), _BlobData(top: 200, left: 80, size: 200, color: Color(0xFFFFB6C1))], child: SafeArea(child: child)));
  static final nordicFrost = AppTheme(name: 'Nordic Frost', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFECEFF1), blobs: const [_BlobData(top: -100, left: -80, size: 500, color: Color(0xFF90A4AE)), _BlobData(top: 150, right: -80, size: 400, color: Color(0xFFB0BEC5)), _BlobData(bottom: -80, left: 30, size: 450, color: Color(0xFFCFD8DC))], child: SafeArea(child: child)));
  static final tangerine = AppTheme(name: 'Tangerine Dream', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFFFF3E0), blobs: const [_BlobData(top: -120, left: -50, size: 460, color: Color(0xFFFF6F00)), _BlobData(top: 100, right: -80, size: 380, color: Color(0xFFFFCA28)), _BlobData(bottom: -100, left: -30, size: 440, color: Color(0xFFFF8A65))], child: SafeArea(child: child)));
  static final lavenderHaze = AppTheme(name: 'Lavender Haze', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFF3E8FF), blobs: const [_BlobData(top: -100, left: -60, size: 450, color: Color(0xFFC084FC)), _BlobData(top: 180, right: -60, size: 400, color: Color(0xFFF0ABFC)), _BlobData(bottom: -90, left: 20, size: 460, color: Color(0xFF93C5FD))], child: SafeArea(child: child)));
  static final forestDew = AppTheme(name: 'Forest Dew', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFE8F5E9), blobs: const [_BlobData(top: -90, left: -70, size: 480, color: Color(0xFF66BB6A)), _BlobData(bottom: -100, right: -70, size: 500, color: Color(0xFF26A69A)), _BlobData(top: 200, left: 40, size: 250, color: Color(0xFFDCEDC8))], child: SafeArea(child: child)));
  static final cyberLime = AppTheme(name: 'Cyber Lime', themeData: _baseTheme(Brightness.dark), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFF101412), blobs: const [_BlobData(top: -110, left: -80, size: 500, color: Color(0xFFD4FF32)), _BlobData(bottom: -110, right: -80, size: 520, color: Color(0xFF00E5CC)), _BlobData(top: 250, left: 60, size: 220, color: Color(0xFF76FF03))], child: SafeArea(child: child)));
  static final strawberryMilk = AppTheme(name: 'Strawberry Milk', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFFFEBEE), blobs: const [_BlobData(top: -80, left: -60, size: 430, color: Color(0xFFFF8A80)), _BlobData(bottom: -90, right: -50, size: 450, color: Color(0xFFFFCCBC)), _BlobData(top: 200, right: 30, size: 200, color: Color(0xFFFFF9C4))], child: SafeArea(child: child)));
  static final oceanBreeze = AppTheme(name: 'Ocean Breeze', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFE0F7FA), blobs: const [_BlobData(top: -100, left: -70, size: 480, color: Color(0xFF4FC3F7)), _BlobData(bottom: -100, right: -70, size: 500, color: Color(0xFF26C6DA)), _BlobData(top: 180, left: 50, size: 240, color: Color(0xFFB2EBF2))], child: SafeArea(child: child)));
  static final desertSand = AppTheme(name: 'Desert Sand', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFFAF3E0), blobs: const [_BlobData(top: -100, left: -60, size: 450, color: Color(0xFFD8B48C)), _BlobData(bottom: -100, right: -60, size: 470, color: Color(0xFFE2725B)), _BlobData(top: 250, left: 80, size: 200, color: Color(0xFFF6EAC2))], child: SafeArea(child: child)));
  static final bubblegum = AppTheme(name: 'Bubblegum Sky', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFFCE4EC), blobs: const [_BlobData(top: -90, left: -60, size: 440, color: Color(0xFF81D4FA)), _BlobData(top: 120, right: -60, size: 400, color: Color(0xFFF48FB1)), _BlobData(bottom: -80, left: 20, size: 460, color: Color(0xFFCE93D8))], child: SafeArea(child: child)));
  static final oliveMinimal = AppTheme(name: 'Olive Minimal', themeData: _baseTheme(Brightness.light), backgroundBuilder: ({required child}) => _MeshWrapper(baseColor: const Color(0xFFF4F1EA), blobs: const [_BlobData(top: -100, left: -80, size: 450, color: Color(0xFF9CA986)), _BlobData(bottom: -100, right: -80, size: 460, color: Color(0xFFD6D0C0)), _BlobData(top: 200, left: 60, size: 220, color: Color(0xFFEDE8D0))], child: SafeArea(child: child)));

  static List<AppTheme> get allThemes => [blendedBright, goldenGreen, aurora, sunset, midnight, sakura, mocha, liquidGlass, matchaLatte, barbieCore, nordicFrost, tangerine, lavenderHaze, forestDew, cyberLime, strawberryMilk, oceanBreeze, desertSand, bubblegum, oliveMinimal];
}
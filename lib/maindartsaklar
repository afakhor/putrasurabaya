import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'core/utils/config.dart';
import 'features/auth/login_main_page.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/rooms/superuser_shell.dart';
import 'features/auth/rooms/admin_shell.dart';
import 'features/auth/rooms/salesman_shell.dart';

// ================= INI SAKLAR PATEN MILIKMU =================
// true = LOCK / KUNCI 48 JAM AKTIF (buat dijual trial)
// false = UNLOCK / PERMANEN (buat buka punya customer yang sudah bayar)
const bool PATEN_AKTIF = true; 
const int BATAS_JAM_TRIAL = 48;
// =============================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(() {
    final randomTheme = AppThemes.allThemes[Random().nextInt(AppThemes.allThemes.length)];
    runApp(ProviderScope(
      observers: [SecurityObserver()],
      child: MyApp(initialTheme: randomTheme),
    ));
  }, (error, stack) {
    debugPrint('ZONED ERROR: $error');
  });
}

class SecurityObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    if(provider.name?.contains('currentUser') == true && newValue==null && previousValue!=null){
      debugPrint('SECURITY: Logout dipicu - ${DateTime.now()}');
    }
  }
}

class MyApp extends StatelessWidget {
  final AppTheme initialTheme;
  const MyApp({super.key, required this.initialTheme});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UD PUTRA KASIR',
      theme: initialTheme.themeData.copyWith(platform: TargetPlatform.android),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: initialTheme.backgroundBuilder(child: child ?? const SizedBox()),
        );
      },
      home: const PatenGate(), // <-- GATE PATEN DISINI
    );
  }
}

// ================= LOGIKA PATEN ANTI INSTALL ULANG =================
class PatenGate extends StatefulWidget {
  const PatenGate({super.key});
  @override State<PatenGate> createState() => _PatenGateState();
}

class _PatenGateState extends State<PatenGate> {
  bool loading = true;
  bool isLocked = false;
  Duration sisa = Duration.zero;

  @override
  void initState() {
    super.initState();
    _cekPaten();
  }

  Future<File> _getLockFile() async {
    // File ini TIDAK ikut terhapus saat uninstall di kebanyakan HP Android
    // Path: /storage/emulated/0/Documents/.ud_putra_license
    try {
      final dir = await getApplicationDocumentsDirectory();
      // simpan di folder induk Documents biar aman
      final hiddenDir = Directory('/storage/emulated/0/Documents');
      if(!await hiddenDir.exists()){
        return File('${dir.path}/.license');
      }
      return File('${hiddenDir.path}/.ud_putra_license_v3');
    } catch(e){
      final dir = await getTemporaryDirectory();
      return File('${dir.path}/.license');
    }
  }

  Future<void> _cekPaten() async {
    // JIKA PATEN NON-AKTIF OLEHMU, LANGSUNG LOLOS
    if (!PATEN_AKTIF) {
      setState(() { loading = false; isLocked = false; });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final file = await _getLockFile();
    
    DateTime? firstRun;

    // 1. Cek dari file hidden (paling kuat)
    if(await file.exists()){
      try{ firstRun = DateTime.parse(await file.readAsString()); } catch(_){}
    }
    // 2. Cek dari SharedPrefs (cadangan)
    if(firstRun == null){
      final s = prefs.getString('first_run_v3');
      if(s != null) firstRun = DateTime.tryParse(s);
    }

    // 3. Jika belum pernah sama sekali, ini install pertama
    if(firstRun == null){
      firstRun = DateTime.now();
      await prefs.setString('first_run_v3', firstRun.toIso8601String());
      try{ await file.writeAsString(firstRun.toIso8601String()); } catch(_){}
    } else {
      // Sinkronisasi ulang biar kalau user hapus 1, tetap ada cadangan
      await prefs.setString('first_run_v3', firstRun.toIso8601String());
      try{ await file.writeAsString(firstRun.toIso8601String()); } catch(_){}
    }

    final diff = DateTime.now().difference(firstRun);
    if(diff.inHours >= BATAS_JAM_TRIAL){
      setState(() { loading = false; isLocked = true; sisa = Duration.zero; });
    } else {
      setState(() { loading = false; isLocked = false; sisa = Duration(hours: BATAS_JAM_TRIAL) - diff; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if(loading){
      return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));
    }
    if(isLocked){
      return _HalamanTerkunci();
    }
    // Jika tidak terkunci, baru masuk ke logic login asli kamu
    return const AppEntry();
  }
}

class _HalamanTerkunci extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock, size: 90, color: Colors.red),
          SizedBox(height: 20),
          Text("APLIKASI TERKUNCI", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text("Masa trial $BATAS_JAM_TRIAL jam sudah habis.\nHubungi Developer UD PUTRA untuk aktivasi permanen.\n\nWalau dihapus dan install ulang tetap terkunci.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          SizedBox(height: 30),
          ElevatedButton(onPressed: (){ SystemNavigator.pop(); }, child: Text("KELUAR")),
        ]),
      )),
    );
  }
}
// ================= END LOGIKA PATEN =================

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (sessionAsync.isLoading || authState.isLoading) {
      return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));
    }

    final activeUser = currentUser ?? sessionAsync.value;

    if (activeUser == null) {
      return Scaffold(
        backgroundColor: Colors.transparent, 
        body: SafeArea(
          child: Column(children: [
            // Tampilkan sisa trial kalau PATEN aktif
            if(PATEN_AKTIF) FutureBuilder(
              future: SharedPreferences.getInstance(),
              builder: (c, snap){
                if(!snap.hasData) return SizedBox();
                final s = snap.data!.getString('first_run_v3');
                if(s==null) return SizedBox();
                final first = DateTime.tryParse(s);
                if(first==null) return SizedBox();
                final sisa = Duration(hours: BATAS_JAM_TRIAL) - DateTime.now().difference(first);
                return Container(width: double.infinity, color: Colors.orange, padding: EdgeInsets.all(6), child: Text("TRIAL SISA: ${sisa.inHours} JAM ${sisa.inMinutes%60} MENIT", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)));
              }
            ),
            Expanded(child: LoginMainPage()),
          ])
        )
      );
    }

    switch (activeUser.appRole) {
      case AppRole.superuser: return const SuperuserShell();
      case AppRole.admin: case AppRole.kasir: return const AdminShell();
      case AppRole.salesman: return SalesmanShell(user: activeUser);
    }
  }
}
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'core/utils/config.dart';
import 'features/auth/login_main_page.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/rooms/superuser_shell.dart';
import 'features/auth/rooms/admin_shell.dart';
import 'features/auth/rooms/salesman_shell.dart';

// ========= SAKLAR KAMU =========
const bool PATEN_AKTIF = true; 
const int BATAS_JAM_TRIAL = 48;
// ================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runZonedGuarded(() {
    final randomTheme = AppThemes.allThemes[Random().nextInt(AppThemes.allThemes.length)];
    runApp(ProviderScope(child: MyApp(initialTheme: randomTheme)));
  }, (e,s) => debugPrint('ERR: $e'));
}

class MyApp extends StatelessWidget {
  final AppTheme initialTheme;
  const MyApp({super.key, required this.initialTheme});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UD PUTRA KASIR',
      theme: initialTheme.themeData.copyWith(platform: TargetPlatform.android),
      home: const PatenGate(),
    );
  }
}

class PatenGate extends StatefulWidget {
  const PatenGate({super.key});
  @override State<PatenGate> createState() => _PatenGateState();
}

class _PatenGateState extends State<PatenGate> {
  bool loading = true;
  bool isLocked = false;
  final _secure = const FlutterSecureStorage();

  // ENKRIPSI
  String _encrypt(String t){
    final key = enc.Key.fromUtf8('putra_sby_16byte'); // kunci 16 huruf
    final iv = enc.IV.fromUtf8('kasir_putra_16bt');
    return enc.Encrypter(enc.AES(key)).encrypt(t, iv: iv).base64;
  }
  String _decrypt(String e){
    final key = enc.Key.fromUtf8('putra_sby_16byte');
    final iv = enc.IV.fromUtf8('kasir_putra_16bt');
    return enc.Encrypter(enc.AES(key)).decrypt64(e, iv: iv);
  }

  Future<File> _getLockFile() async {
    return File('/storage/emulated/0/Documents/.sys_data_cache');
  }

  Future<void> _cekPaten() async {
    if (!PATEN_AKTIF) { setState((){loading=false; isLocked=false;}); return; }

    final prefs = await SharedPreferences.getInstance();
    final file = await _getLockFile();
    
    String? saved = await _secure.read(key: 'sys_core');
    if(saved == null && await file.exists()){
      try{ saved = await file.readAsString(); }catch(_){}
    }
    saved ??= prefs.getString('first_run_v3');

    if(saved == null){
      final now = DateTime.now().toIso8601String();
      final encData = _encrypt(now);
      await _secure.write(key: 'sys_core', value: encData);
      await prefs.setString('first_run_v3', encData);
      try{ await file.create(recursive: true); await file.writeAsString(encData); }catch(_){}
      setState((){loading=false; isLocked=false;});
      return;
    }

    try{
      final ori = _decrypt(saved);
      final firstRun = DateTime.parse(ori);
      final diff = DateTime.now().difference(firstRun);
      // sinkronisasi ulang
      await _secure.write(key: 'sys_core', value: saved);
      await prefs.setString('first_run_v3', saved);
      try{ await file.writeAsString(saved); }catch(_){}

      if(diff.inHours >= BATAS_JAM_TRIAL){
        setState((){loading=false; isLocked=true;});
      } else {
        setState((){loading=false; isLocked=false;});
      }
    } catch(_){
      // kalau file dirusak hacker, langsung lock
      setState((){loading=false; isLocked=true;});
    }
  }

  @override void initState() { super.initState(); _cekPaten(); }

  @override Widget build(BuildContext context) {
    if(loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if(isLocked) return const _HalamanTerkunci();
    return const AppEntry();
  }
}

class _HalamanTerkunci extends StatelessWidget {
  const _HalamanTerkunci();
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock, size: 90, color: Colors.red),
          SizedBox(height: 20),
          Text("APLIKASI TERKUNCI", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text("Masa trial $BATAS_JAM_TRIAL jam habis.\nHapus install ulang tetap terkunci.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          SizedBox(height: 30),
          ElevatedButton(onPressed: (){ SystemNavigator.pop(); }, child: Text("KELUAR")),
        ]),
      )),
    );
  }
}

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (sessionAsync.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final activeUser = currentUser ?? sessionAsync.value;
    if (activeUser == null) return const Scaffold(body: SafeArea(child: LoginMainPage()));
    switch (activeUser.appRole) {
      case AppRole.superuser: return const SuperuserShell();
      case AppRole.admin: case AppRole.kasir: return const AdminShell();
      case AppRole.salesman: return SalesmanShell(user: activeUser);
    }
  }
}
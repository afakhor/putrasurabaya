import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'core/utils/config.dart';
import 'features/auth/login_main_page.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/rooms/superuser_shell.dart';
import 'features/auth/rooms/admin_shell.dart';
import 'features/auth/rooms/salesman_shell.dart';

const bool PATEN_AKTIF = true; 
const int BATAS_JAM_TRIAL = 48;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runZonedGuarded(() {
    final randomTheme = AppThemes.allThemes[Random().nextInt(AppThemes.allThemes.length)];
    runApp(ProviderScope(observers: [SecurityObserver()], child: MyApp(initialTheme: randomTheme)));
  }, (e,s) => debugPrint('ERR: $e'));
}

class SecurityObserver extends ProviderObserver {
  @override void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    if(provider.name?.contains('currentUser') == true && newValue==null && previousValue!=null){
      debugPrint('SECURITY: Logout ${DateTime.now()}');
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: initialTheme.backgroundBuilder(child: child ?? const SizedBox()),
      ),
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
  String lockReason = "";
  final _secure = const FlutterSecureStorage();

  String _encrypt(String t){
    final key = enc.Key.fromUtf8('putra_sby_16byte');
    final iv = enc.IV.fromUtf8('kasir_putra_16bt');
    return enc.Encrypter(enc.AES(key)).encrypt(t, iv: iv).base64;
  }
  String _decrypt(String e){
    final key = enc.Key.fromUtf8('putra_sby_16byte');
    final iv = enc.IV.fromUtf8('kasir_putra_16bt');
    return enc.Encrypter(enc.AES(key)).decrypt64(e, iv: iv);
  }

  // ===== GEMBOK 3: CEK ROOT =====
  Future<bool> _isRooted() async {
    // cek file su yang umum
    final paths = ['/system/bin/su', '/system/xbin/su', '/system/app/Superuser.apk', '/sbin/su'];
    for (final p in paths) { if (await File(p).exists()) return true; }
    // cek buildTags test-keys (ROM custom root)
    try {
      final buildTags = (await File('/system/build.prop').readAsString()).contains('test-keys');
      if(buildTags) return true;
    } catch(_){}
    return false;
  }

  // ===== GEMBOK 4: CEK JAM ASLI DARI INTERNET (ANTI MUNDUR JAM) =====
  Future<DateTime> _getRealTime() async {
    try {
      final res = await http.get(Uri.parse('https://worldtimeapi.org/api/ip')).timeout(Duration(seconds: 3));
      if(res.statusCode==200){
        final data = jsonDecode(res.body);
        return DateTime.parse(data['datetime']);
      }
    } catch(_){}
    // kalau offline, pakai jam HP tapi kasih toleransi
    return DateTime.now();
  }

  // ===== GEMBOK 5: ANTI FRIDA / HOOK =====
  Future<bool> _isHooked() async {
    try {
      // Frida biasanya buka port 27042
      final result = await Socket.connect('127.0.0.1', 27042, timeout: Duration(milliseconds: 300));
      result.destroy();
      return true; // port frida kebuka = lagi di-hook
    } catch(_){ return false; }
  }

  Future<File> _getLockFile() async => File('/storage/emulated/0/Documents/.sys_data_cache_v4');

  Future<void> _cekPaten() async {
    if (!PATEN_AKTIF) { if(mounted) setState((){loading=false; isLocked=false;}); return; }

    // 1. Cek Root dulu
    if(await _isRooted()){
      setState((){loading=false; isLocked=true; lockReason="Perangkat terdeteksi ROOT. Hubungi Developer.";});
      return;
    }
    // 2. Cek Frida
    if(await _isHooked()){
      setState((){loading=false; isLocked=true; lockReason="Deteksi debugging ilegal.";});
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final file = await _getLockFile();
    final realNow = await _getRealTime(); // jam jujur dari internet
    
    String? saved = await _secure.read(key: 'sys_core_v4');
    if(saved == null && await file.exists()){ try{ saved = await file.readAsString(); }catch(_){} }
    saved ??= prefs.getString('first_run_v4');

    if(saved == null){
      final encData = _encrypt(realNow.toIso8601String());
      await _secure.write(key: 'sys_core_v4', value: encData);
      await prefs.setString('first_run_v4', encData);
      try{ await file.create(recursive: true); await file.writeAsString(encData); }catch(_){}
      if(mounted) setState((){loading=false; isLocked=false;});
      return;
    }

    try{
      final ori = _decrypt(saved);
      final firstRun = DateTime.parse(ori);
      // LOGIKA ANTI MUNDUR JAM: kalau jam HP lebih kecil dari firstRun, anggap curang -> LOCK
      if(realNow.isBefore(firstRun.subtract(Duration(hours: 1)))){
        setState((){loading=false; isLocked=true; lockReason="Waktu perangkat tidak valid.";});
        return;
      }
      final diff = realNow.difference(firstRun);
      await _secure.write(key: 'sys_core_v4', value: saved);
      await prefs.setString('first_run_v4', saved);
      try{ await file.writeAsString(saved); }catch(_){}

      if(mounted){
        if(diff.inHours >= BATAS_JAM_TRIAL){
          setState((){loading=false; isLocked=true; lockReason="";});
        } else {
          setState((){loading=false; isLocked=false;});
        }
      }
    } catch(_){
      if(mounted) setState((){loading=false; isLocked=true; lockReason="Lisensi rusak.";});
    }
  }

  @override void initState() { super.initState(); _cekPaten(); }

  @override Widget build(BuildContext context) {
    if(loading) return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));
    if(isLocked) return _HalamanTerkunci(reason: lockReason);
    return const AppEntry();
  }
}

class _HalamanTerkunci extends StatelessWidget {
  final String reason;
  const _HalamanTerkunci({this.reason=""});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock, size: 90, color: Colors.red),
          const SizedBox(height: 20),
          const Text("APLIKASI TERKUNCI", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(reason.isEmpty ? "Masa trial $BATAS_JAM_TRIAL jam habis.\nHapus install ulang tetap terkunci." : reason, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: (){ SystemNavigator.pop(); }, child: const Text("KELUAR")),
        ]),
      )),
    );
  }
}

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});
  String _decryptBanner(String e){
    try{
      final key = enc.Key.fromUtf8('putra_sby_16byte');
      final iv = enc.IV.fromUtf8('kasir_putra_16bt');
      return enc.Encrypter(enc.AES(key)).decrypt64(e, iv: iv);
    }catch(_){ return ""; }
  }
  @override Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (sessionAsync.isLoading) return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));
    final activeUser = currentUser ?? sessionAsync.value;
    if (activeUser == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: Column(children: [
          if(PATEN_AKTIF) FutureBuilder<String?>(
            future: const FlutterSecureStorage().read(key: 'sys_core_v4'),
            builder: (c, snap){
              if(!snap.hasData || snap.data==null) return const SizedBox();
              final ori = _decryptBanner(snap.data!);
              final first = DateTime.tryParse(ori);
              if(first==null) return const SizedBox();
              final sisa = Duration(hours: BATAS_JAM_TRIAL) - DateTime.now().difference(first);
              if(sisa.isNegative) return const SizedBox();
              return Container(width: double.infinity, color: Colors.orange, padding: const EdgeInsets.all(6), child: Text("TRIAL SISA: ${sisa.inHours} JAM", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)));
            }
          ),
          const Expanded(child: LoginMainPage()),
        ])),
      );
    }
    switch (activeUser.appRole) {
      case AppRole.superuser: return const SuperuserShell();
      case AppRole.admin: case AppRole.kasir: return const AdminShell();
      case AppRole.salesman: return SalesmanShell(user: activeUser);
    }
  }
}
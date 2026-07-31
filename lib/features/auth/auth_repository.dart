import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/user_dao.dart';

class AuthRepository {
  final UserDao userDao;
  AuthRepository(this.userDao);

  // 1. PINTU SUPERUSER / OWNER / ADMIN (pakai username + password)
  Future<UserData?> loginByPassword(String username, String password) async {
    // TODO: nanti ganti jadi hash beneran pakai bcrypt/sha256
    final hash = password; 
    final user = await userDao.validateUserPassword(username, hash);
    
    // Security: pastikan yang login lewat sini cuma role tinggi
    if (user != null && (user.role == 'salesman' || user.role == 'kasir')) {
      // Salesman/Kasir tidak boleh login pakai password, harus PIN/API Key
      throw Exception('Role ${user.role} wajib login pakai PIN / API Key');
    }
    return user;
  }

  // 2. PINTU KASIR (PIN 6 digit)
  Future<UserData?> loginByPin(String pin) {
    return userDao.validatePin(pin);
  }

  // 3. PINTU SALESMAN (API Key / QR Scan)
  Future<UserData?> loginByApiKey(String apiKey) async {
    // Bersihkan spasi kalau hasil scan QR ada newline
    final cleanKey = apiKey.trim();
    return userDao.validateApiKey(cleanKey);
  }

  // 4. PINTU UNIVERSAL (iPOS 5 Style) - 1 input bisa coba semua
  // Enak buat di HP: user tinggal tempel, sistem yang nebak itu PIN atau API Key
  Future<UserData?> loginUniversal(String input) async {
    final clean = input.trim();
    
    // Coba sebagai PIN dulu (kalau 6 digit angka)
    if (clean.length == 6 && int.tryParse(clean) != null) {
      final byPin = await loginByPin(clean);
      if (byPin != null) return byPin;
    }
    
    // Coba sebagai API Key (format KEY-xxxx)
    if (clean.startsWith('KEY-')) {
      final byKey = await loginByApiKey(clean);
      if (byKey != null) return byKey;
    }
    
    // Jika bukan keduanya, anggap username (nanti butuh password terpisah)
    return null;
  }
}
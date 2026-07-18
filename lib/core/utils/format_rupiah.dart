import 'package:flutter/services.dart'; // Wajib ditambahkan untuk TextInputFormatter
import 'package:intl/intl.dart';

/// ==========================================
/// 1. FORMATTER UNTUK TAMPILAN DATA (DISPLAY)
/// ==========================================

/// Fungsi standar untuk mengubah angka menjadi format Rupiah
String formatRupiah(num nominal) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0, // Mengabaikan koma koin sen (,00) agar kasir lebih bersih
  );
  return formatter.format(nominal);
}

/// Extension opsional agar Bapak bisa memanggil langsung dari angka/variabelnya.
/// Contoh pemakaian: `text: 50000.toRupiah()` atau `tx.total.toRupiah()`
extension RupiahFormatter on num {
  String toRupiah() {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(this);
  }
}

/// ==========================================
/// 2. FORMATTER UNTUK FORM INPUT (REAL-TIME)
/// ==========================================

/// Formatter Kustom untuk TextFormField agar otomatis memformat titik ribuan saat diketik
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Jika kolom dikosongkan, kembalikan nilai kosong
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Hanya ambil karakter angka (menghapus titik jika ada)
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Ubah string angka menjadi integer
    final int value = int.parse(cleanText);
    
    // Gunakan format lokal Indonesia untuk ribuan (menghasilkan format: 150.000)
    final formatter = NumberFormat.decimalPattern('id_ID');
    String newText = formatter.format(value);

    // Kembalikan teks baru dengan posisi kursor selalu berada di paling akhir teks
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

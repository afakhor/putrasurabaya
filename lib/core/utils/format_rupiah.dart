import 'package:intl/intl.dart';

String formatRupiah(num number) {
  final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  return format.format(number);
}

String formatAngka(num number) {
  final format = NumberFormat("#,##0", "id_ID");
  return format.format(number);
}
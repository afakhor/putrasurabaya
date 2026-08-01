// lib/core/database/daos/dashboard_finance_summary.dart - FINAL
class DashboardFinanceSummary {
  final double omsetHariIni;
  final int jumlahTransaksiHariIni;
  final double labaKotorHariIni;
  final double pengeluaranHariIni;
  final double totalSisaHutang;
  final int jumlahHutangAktif;
  final double totalSisaPiutang;
  final int jumlahPiutangAktif;
  final int stokMenipisCount;

  DashboardFinanceSummary({
    required this.omsetHariIni,
    required this.jumlahTransaksiHariIni,
    required this.labaKotorHariIni,
    required this.pengeluaranHariIni,
    required this.totalSisaHutang,
    required this.jumlahHutangAktif,
    required this.totalSisaPiutang,
    required this.jumlahPiutangAktif,
    required this.stokMenipisCount,
  });

  // ALIAS biar dashboard_owner_page.dart lama yang manggil todaySales & totalReceivable gak error lagi
  double get todaySales => omsetHariIni;
  double get totalReceivable => totalSisaPiutang;
  double get totalPayable => totalSisaHutang;
}
class DashboardFinanceSummary {
  final double totalSisaHutang;      // Total Hutang Usaha ke Supplier
  final int jumlahHutangAktif;        // Jumlah Transaksi Hutang Belum Lunas
  final double totalSisaPiutang;     // Total Piutang Usaha dari Customer
  final int jumlahPiutangAktif;       // Jumlah Transaksi Piutang Belum Lunas

  DashboardFinanceSummary({
    required this.totalSisaHutang,
    required this.jumlahHutangAktif,
    required this.totalSisaPiutang,
    required this.jumlahPiutangAktif,
  });

  factory DashboardFinanceSummary.empty() => DashboardFinanceSummary(
        totalSisaHutang: 0,
        jumlahHutangAktif: 0,
        totalSisaPiutang: 0,
        jumlahPiutangAktif: 0,
      );
}

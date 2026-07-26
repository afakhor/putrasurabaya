class NeracaModel {
  // Aktiva (Assets)
  final double kasDanBank;
  final double piutangUsaha;
  final double nilaiPersediaanBarang;
  final double totalAktiva;

  // Pasiva (Kewajiban + Ekuitas)
  final double hutangUsaha;
  final double modalDanLabaDitahan;
  final double totalPasiva;

  final bool isBalanced;

  NeracaModel({
    required this.kasDanBank,
    required this.piutangUsaha,
    required this.nilaiPersediaanBarang,
    required this.totalAktiva,
    required this.hutangUsaha,
    required this.modalDanLabaDitahan,
    required this.totalPasiva,
    required this.isBalanced,
  });
}

final neracaProvider = FutureProvider<NeracaModel>((ref) async {
  final db = ref.watch(localDatabaseProvider);

  // 1. Piutang Usaha (Total Sisa Piutang Customer Belum Lunas)
  final activeReceivables = await (db.select(db.receivables)
        ..where((r) => r.status.isNotIn(['paid'])))
      .get();
  double totalPiutang = activeReceivables.fold(0, (sum, item) => sum + item.remainingAmount);

  // 2. Nilai Persediaan Barang Dagangan (Stok Aktif x HPP Saat Ini)
  final products = await db.select(db.products).get();
  double totalPersediaan = products.fold(0, (sum, item) => sum + (item.stock * item.buyPrice));

  // 3. Hutang Usaha (Total Sisa Hutang Ke Supplier Belum Lunas)
  final activePayables = await (db.select(db.payables)
        ..where((p) => p.status.isNotIn(['paid'])))
      .get();
  double totalHutang = activePayables.fold(0, (sum, item) => sum + item.remainingAmount);

  // 4. Kalkulasi Estimasi Kas & Bank (Penjualan Tunai + Pelunasan Piutang - Pembayaran Hutang - Beban)
  final salesCash = await (db.select(db.transactions)
        ..where((t) => t.paymentMethod.equals('cash'))
        ..where((t) => t.status.equals('completed')))
      .get();
  double totalSalesCash = salesCash.fold(0, (sum, t) => sum + t.finalAmount);

  final payments = await db.select(db.debtPayments).get();
  double totalTerimaPiutang = 0;
  double totalBayarHutang = 0;

  for (var p in payments) {
    if (p.type == 'receivable_collect') totalTerimaPiutang += p.amount;
    if (p.type == 'payable_pay') totalBayarHutang += p.amount;
  }

  final allExpenses = await db.select(db.expenses).get();
  double totalBeban = allExpenses.fold(0, (sum, e) => sum + e.amount);

  double estimasiKas = totalSalesCash + totalTerimaPiutang - totalBayarHutang - totalBeban;

  // Sisi Aktiva
  double totalAktiva = estimasiKas + totalPiutang + totalPersediaan;

  // Sisi Pasiva
  double modalEkuitas = totalAktiva - totalHutang; // Ekuitas Penyeimbang
  double totalPasiva = totalHutang + modalEkuitas;

  return NeracaModel(
    kasDanBank: estimasiKas,
    piutangUsaha: totalPiutang,
    nilaiPersediaanBarang: totalPersediaan,
    totalAktiva: totalAktiva,
    hutangUsaha: totalHutang,
    modalDanLabaDitahan: modalEkuitas,
    totalPasiva: totalPasiva,
    isBalanced: (totalAktiva - totalPasiva).abs() < 0.01,
  );
});

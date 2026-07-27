import 'package:drift/drift.dart';

/// Tabel Header Transaksi Penjualan (Nota Kasir)
@DataClassName('TransactionData')
class Transactions extends Table {
  /// Unique ID Transaksi (Contoh: TRX-1722071234)
  TextColumn get id => text()();

  /// Tanggal dan Waktu Transaksi
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  /// Total Belanja (Setelah diskon jika ada)
  RealColumn get total => real().withDefault(const Constant(0.0))();

  /// Uang yang Dibayarkan oleh Pembeli
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();

  /// Kembalian Transaksi Tunai
  RealColumn get changeAmount => real().withDefault(const Constant(0.0))();

  /// Metode Pembayaran (cash, transfer, tempo, dp)
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();

  /// Optional ID Pelanggan (jika transaksi atas nama pelanggan/piutang)
  TextColumn get customerId => text().nullable()();

  /// Catatan Tambahan
  TextColumn get notes => text().nullable()();

  /// Status Sinkronisasi ke Server (false = lokal saja, true = sudah ter-upload)
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel Detail Produk yang Dibeli dalam Transaksi
@DataClassName('TransactionItemData')
class TransactionItems extends Table {
  /// Unique ID Item Transaksi
  TextColumn get id => text()();

  /// Relasi ke ID Header Transaksi
  TextColumn get transactionId => text()();

  /// ID Produk
  TextColumn get productId => text()();

  /// Nama Produk saat transaksi (Disimpan agar riwayat tidak berubah meski nama produk diubah)
  TextColumn get productName => text()();

  /// Harga Jual per Unit saat transaksi
  RealColumn get price => real()();

  /// Harga Modal / Kulakan saat transaksi (Wajib ada untuk menghitung estimasi Laba Bersih)
  RealColumn get buyPriceAtTransaction =>
      real().withDefault(const Constant(0.0))();

  /// Jumlah Barang
  IntColumn get quantity => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

import 'package:drift/drift.dart';
import 'customer_table.dart';
import 'product_table.dart';

// ==========================================
// 1. HEADER TRANSAKSI PENJUALAN (TRANSACTIONS)
// ==========================================
@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()(); 
  TextColumn get invoiceNo => text()(); // Nomor Faktur / Nota (Misal: TRX-20260729-0001)
  TextColumn get salesId => text().nullable()(); // Salesman / Kasir yang melayani
  TextColumn get shiftId => text().nullable()(); // ID Shift Kasir aktif
  TextColumn get customerId => text().nullable().references(Customers, #id)(); // Nullable jika Pelanggan Umum/Eceran

  // Perhitungan Keuangan Transaksi
  RealColumn get subtotal => real()(); // Total akumulasi subtotal item
  RealColumn get discountTotal => real().withDefault(const Constant(0.0))(); // Diskon Nota / Potongan Akhir
  RealColumn get taxTotal => real().withDefault(const Constant(0.0))(); // PPn / Pajak
  RealColumn get grandTotal => real()(); // Formula: (subtotal - discountTotal) + taxTotal

  RealColumn get payAmount => real().withDefault(const Constant(0.0))(); // Total Uang Dibayar Pelanggan
  RealColumn get remainingDebt => real().withDefault(const Constant(0.0))(); // Sisa Piutang jika Kredit/Cicil
  RealColumn get changeAmount => real().withDefault(const Constant(0.0))(); // Uang Kembalian Kasir

  // Metode & Status Pembayaran
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))(); // cash, transfer, credit, qris
  TextColumn get status => text().withDefault(const Constant('paid'))(); // paid, partial, unpaid, void
  DateTimeColumn get dueDate => dateTime().nullable()(); // Jatuh tempo jika piutang

  // Catatan Tambahan & Bukti Transaksi
  TextColumn get notes => text().nullable()(); // Catatan transaksi / Alasan Void jika dibatalkan
  TextColumn get proofImage => text().nullable()(); // Path foto nota bertanda tangan pelanggan

  // Auditing & Offline Sync
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override 
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 2. DETAIL ITEM TRANSAKSI (TRANSACTION ITEMS)
// ==========================================
@DataClassName('TransactionItemData')
class TransactionItems extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text().references(Transactions, #id)(); 
  TextColumn get productId => text().references(Products, #id)(); 
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)(); // Support Varian Produk

  // Snapshot Informasi Produk (Tetap aman jika master produk diubah nanti)
  TextColumn get productName => text()(); 
  TextColumn get unit => text()(); // PCS, DUS, BAL, PACK, dll.
  RealColumn get conversionFactor => real().withDefault(const Constant(1.0))(); // Faktor pengali ke stok Pcs dasar
  RealColumn get quantity => real()(); // Jumlah yang dibeli dalam satuan `unit`

  // HPP / Modal saat Transaksi (Guna Perhitungan Laba Rugi Akurat)
  RealColumn get buyPriceAtTransaction => real().withDefault(const Constant(0.0))(); 

  // --- MODEL HARGA TIER ---
  RealColumn get tier1Price => real()(); // Snapshot Harga Tier 1 (Eceran)
  RealColumn get tier2Price => real()(); // Snapshot Harga Tier 2 (Grosir Kecil)
  RealColumn get tier3Price => real()(); // Snapshot Harga Tier 3 (Grosir Besar)

  IntColumn get selectedTier => integer().withDefault(const Constant(1))(); // Tier yang dipilih (1, 2, atau 3)
  RealColumn get appliedTierPrice => real()(); // Harga satuan efektif yang dipakai

  RealColumn get itemDiscount => real().withDefault(const Constant(0.0))(); // Diskon khusus item jika ada
  RealColumn get subtotal => real()(); // Formula: (quantity * appliedTierPrice) - itemDiscount

  // Auditing & Offline Sync
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override 
  Set<Column> get primaryKey => {id};
}

// ==========================================
// HELPER KONSTANTA STATUS TRANSAKSI
// ==========================================
abstract class TransactionStatus {
  static const String paid = 'paid';
  static const String partial = 'partial';
  static const String unpaid = 'unpaid';
  static const String voided = 'void';
}

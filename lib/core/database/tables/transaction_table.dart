import 'package:drift/drift.dart';
import 'product_table.dart';

/// HEADER TRANSAKSI PENJUALAN
@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()(); 
  TextColumn get invoiceNo => text()(); // Nomor Faktur / Nota
  TextColumn get salesId => text().nullable()(); // User Kasir / Salesman
  TextColumn get shiftId => text().nullable()(); // ID Shift Kasir (Dipertahankan dari tabel lama)
  TextColumn get customerId => text().nullable()(); // ID Pelanggan (Nullable jika Eceran)

  // Perhitungan Keuangan (Murni Tanpa Discount)
  RealColumn get subtotal => real()(); // Total akumulasi subtotal item
  RealColumn get taxTotal => real().withDefault(const Constant(0.0))(); // Pajak jika ada (Dipertahankan)
  RealColumn get grandTotal => real()(); // Total tagihan akhir (subtotal + taxTotal)
  
  RealColumn get payAmount => real().withDefault(const Constant(0.0))(); // Total Uang Dibayar (paid)
  RealColumn get remainingDebt => real().withDefault(const Constant(0.0))(); // Sisa Piutang (debt)
  RealColumn get changeAmount => real().withDefault(const Constant(0.0))(); // Uang Kembalian (change)

  // Metode & Status Pembayaran
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))(); // cash, transfer, credit
  TextColumn get status => text().withDefault(const Constant('paid'))(); // paid, partial, unpaid, void
  DateTimeColumn get dueDate => dateTime().nullable()(); // Jatuh tempo jika piutang/kredit
  
  // Auditing & Offline Sync
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // Status sync server (Dipertahankan)

  @override 
  Set<Column> get primaryKey => {id};
}

/// DETAIL ITEM TRANSAKSI PENJUALAN
@DataClassName('TransactionItemData')
class TransactionItems extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text().references(Transactions, #id)(); 
  TextColumn get productId => text().references(Products, #id)(); 
  
  // Snapshot Informasi Produk (Aman jika master produk diubah di kemudian hari)
  TextColumn get productName => text()(); 
  TextColumn get unit => text()(); // PCS, DUS, BAL, dll.
  RealColumn get quantity => real()();
  
  // HPP / Modal saat Transaksi
  RealColumn get buyPriceAtTransaction => real().withDefault(const Constant(0.0))(); 

  // --- MODEL HARGA TIER (MENGGANTIKAN DISCOUNT) ---
  RealColumn get tier1Price => real()(); // Snapshot Harga Tier 1 (Eceran)
  RealColumn get tier2Price => real()(); // Snapshot Harga Tier 2 (Grosir Kecil)
  RealColumn get tier3Price => real()(); // Snapshot Harga Tier 3 (Grosir Besar)
  
  IntColumn get selectedTier => integer().withDefault(const Constant(1))(); // Tier yang dipilih (1, 2, atau 3)
  RealColumn get appliedTierPrice => real()(); // Harga satuan yang dipakai (Menggantikan 'price' lama)

  RealColumn get subtotal => real()(); // Formula: quantity * appliedTierPrice

  @override 
  Set<Column> get primaryKey => {id};
}

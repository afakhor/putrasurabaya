import 'package:drift/drift.dart';
import 'product_table.dart';
import 'supplier_table.dart';

// ==========================================
// 1. TABEL HEADER PEMBELIAN (PURCHASES)
// ==========================================
@DataClassName('PurchaseData')
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNo => text()(); // No Nota / Faktur dari Supplier
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get userId => text()(); // Admin / Operator Gudang yang menginput

  RealColumn get totalAmount => real()(); // Total Belanja
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))(); // Terbayar saat transaksi
  RealColumn get debtAmount => real().withDefault(const Constant(0.0))(); // Sisa Hutang ke Supplier
  
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))(); // 'cash', 'transfer', 'credit'
  TextColumn get status => text().withDefault(const Constant('lunas'))(); // 'lunas', 'hutang', 'draf'
  DateTimeColumn get dueDate => dateTime().nullable()(); // Jatuh Tempo Kredit Supplier
  
  TextColumn get notes => text().nullable()();
  
  // Status Offline Sync & Timestamp
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 2. TABEL DETAIL ITEM PEMBELIAN (PURCHASE ITEMS)
// ==========================================
@DataClassName('PurchaseItemData')
class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text().references(Purchases, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable().references(ProductVariants, #id)();

  // Multi Satuan (Misal: Beli 1 Dus isi 24 Pcs)
  TextColumn get unitName => text().withDefault(const Constant('Pcs'))(); // Satuan saat dibeli
  RealColumn get conversionFactor => real().withDefault(const Constant(1.0))(); // Pengali ke Pcs dasar
  
  RealColumn get quantity => real()(); // Jumlah unit yang dibeli dalam unitName
  RealColumn get buyPrice => real()(); // Harga beli per unitName
  RealColumn get subtotal => real()(); // quantity * buyPrice

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

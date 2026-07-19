import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'local_database.g.dart';

@DataClassName('UserData')
class Users extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get role => text()(); // 'owner' atau 'salesman'
  TextColumn get status => text()(); 
  BoolColumn get canEditPrice => boolean().withDefault(const Constant(false))();
  BoolColumn get canDeleteTransaction => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductData')
class Products extends Table {
  TextColumn get id => text()(); // SKU Utama / Auto Generated
  TextColumn get name => text()();
  TextColumn get shortName => text().withLength(max: 25).nullable()(); // Untuk struk thermal 58mm
  TextColumn get barcode => text().nullable()();
  TextColumn get description => text().nullable()();
  
  // Klasifikasi & Lokasi
  TextColumn get categoryId => text().withDefault(const Constant('Umum'))();
  TextColumn get subCategory => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get warehouseLocation => text().nullable()(); // Gudang/Rak (Owner Only)
  TextColumn get tags => text().nullable()();

  // Pricing Engine (Base Unit)
  RealColumn get buyPrice => real().withDefault(const Constant(0))(); // Modal / HPP
  RealColumn get sellPriceGeneral => real().withDefault(const Constant(0))(); // Umum
  RealColumn get sellPriceTier1 => real().withDefault(const Constant(0))(); // Grosir Tier 1
  RealColumn get sellPriceTier2 => real().withDefault(const Constant(0))(); // Grosir Tier 2
  RealColumn get sellPriceTier3 => real().withDefault(const Constant(0))(); // Grosir Tier 3
  RealColumn get maxDiscountSales => real().withDefault(const Constant(0))(); // Limit Diskon Sales
  BoolColumn get isPriceLocked => boolean().withDefault(const Constant(true))(); // Kunci harga untuk Sales

  // Stock Control
  RealColumn get stock => real().withDefault(const Constant(0))();
  RealColumn get minStock => real().withDefault(const Constant(5))();
  RealColumn get maxStock => real().withDefault(const Constant(100))();
  BoolColumn get allowMinusStock => boolean().withDefault(const Constant(false))();

  // Compliance & Metadata
  RealColumn get weight => real().withDefault(const Constant(0))(); // Gram untuk ongkir
  TextColumn get dimensions => text().nullable()(); // P x L x T
  RealColumn get ppnPercent => real().withDefault(const Constant(0))();
  IntColumn get rewardPoints => integer().withDefault(const Constant(0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get statusActive => text().withDefault(const Constant('aktif'))(); // aktif / non-aktif

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductAssetData')
class ProductAssets extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get imagePath => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductUnitData')
class ProductUnits extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)(); 
  TextColumn get unitName => text()(); // Pcs, Dus, Renceng, Karton
  IntColumn get conversion => integer()(); // Isi konversi misal 12 pcs
  RealColumn get buyPriceUnit => real()(); 
  RealColumn get sellPriceUnit => real()();
  TextColumn get barcode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductVariantData')
class ProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get skuVariant => text()();
  TextColumn get variantName => text()(); // Warna, Ukuran (Contoh: Kunci Pas 10mm Kuning)
  TextColumn get barcode => text().nullable()();
  RealColumn get stock => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductPromoData')
class ProductPromos extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  RealColumn get discountNominal => real().withDefault(const Constant(0))();
  TextColumn get promoType => text().withDefault(const Constant('regular'))(); // bundling, buy_x_get_y
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SupplierData')
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get leadTimeDays => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable()();
  TextColumn get type => text()(); // 'masuk', 'keluar', 'retur', 'opname'
  RealColumn get quantity => real()();
  RealColumn get hppSnapshot => real()(); // Nilai HPP saat mutasi terjadi
  RealColumn get currentStockSnapshot => real()(); // Sisa stok setelah mutasi
  TextColumn get referenceNo => text()(); // No Invoice / Dokumen Opname
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Model data transaksi lama dipertahankan
@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()(); 
  TextColumn get invoiceNo => text()();
  RealColumn get subtotal => real()();
  RealColumn get total => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  RealColumn get debt => real().withDefault(const Constant(0))();
  RealColumn get change => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); 

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionItemData')
class TransactionItems extends Table {
  TextColumn get id => text()(); 
  TextColumn get transactionId => text()(); 
  TextColumn get productId => text()(); 
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  TextColumn get unit => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Users, Products, ProductAssets, ProductUnits, ProductVariants, 
  ProductPromos, Suppliers, StockMutations, Transactions, TransactionItems
])
class LocalDatabase extends _$LocalDatabase { 
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4; 

  Future<List<ProductData>> getAllProducts() => select(products).get();

  // Algoritma hitung HPP menggunakan metode Moving Average (Nilai rata-rata tertimbang modal)
  Future<void> catatMutasiStok({
    required String productId,
    required String type,
    required double qty,
    required double hargaBeliMasuk,
    required String refNo,
    String? variantId,
    String? catatan,
  }) async {
    await transaction(() async {
      final queryProd = select(products)..where((t) => t.id.equals(productId));
      final prod = await queryProd.getSingle();

      double stokLama = prod.stock;
      double hppLama = prod.buyPrice;
      double stokBaru = type == 'masuk' || type == 'retur' ? stokLama + qty : stokLama - qty;
      
      double hppBaru = hppLama;
      if (type == 'masuk' && (stokLama + qty) > 0) {
        // Rumus Moving Average: ((Stok Awal * HPP Awal) + (Stok Masuk * Harga Masuk)) / Total Stok Baru
        hppBaru = ((stokLama * hppLama) + (qty * hargaBeliMasuk)) / (stokLama + qty);
      }

      // Update Master Produk
      await (update(products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          stock: Value(stokBaru),
          buyPrice: Value(hppBaru),
        ),
      );

      // Insert Kartu Stok Log
      await into(stockMutations).insert(StockMutationsCompanion.insert(
        id: 'MUT-${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        variantId: Value(variantId),
        type: type,
        quantity: qty,
        hppSnapshot: hppBaru,
        currentStockSnapshot: stokBaru,
        referenceNo: refNo,
        notes: Value(catatan),
        date: Value(DateTime.now()),
      ));
    });
  }
  // Tambahkan method ini di dalam class LocalDatabase (misalnya di bawah catatMutasiStok)
  Future<void> prosesTransaksiPenyimpanan({
    required TransactionsCompanion dataTransaksi,
    required List<TransactionItemsCompanion> itemTransaksi,
  }) async {
    await transaction(() async {
      // 1. Simpan data header transaksi (Invoice, Total, Bayar, dll)
      await into(transactions).insert(dataTransaksi);

      // 2. Loop untuk simpan item belanjaan & potong stok produk
      for (final item in itemTransaksi) {
        await into(transactionItems).insert(item);

        // 3. Potong stok otomatis menggunakan method catatMutasiStok yang sudah Anda buat
        // Karena ini transaksi keluar (penjualan), hargaBeliMasuk diisi 0 karena tidak mengubah HPP modal
        await catatMutasiStok(
          productId: item.productId.value,
          type: 'keluar',
          qty: item.quantity.value,
          hargaBeliMasuk: 0, 
          refNo: dataTransaksi.invoiceNo.value,
          catatan: 'Penjualan POS - No Invoice: ${dataTransaksi.invoiceNo.value}',
        );
      }
    });
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'putra_sby_db');
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());

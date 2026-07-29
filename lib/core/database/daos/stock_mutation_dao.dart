import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/product_tables.dart';

part 'stock_mutation_dao.g.dart';

// ===========================================================================
// CONSTANTS & ENUMS UNTUK MUTASI STOK (5 SUMBER ATURAN EMAS)
// ===========================================================================

class StockMutationType {
  // Sumber Menambah Stok
  static const String pembelian = 'PEMBELIAN'; // Beli dari Supplier
  static const String itemMasuk = 'ITEM_MASUK'; // Manual In (Non-Pembelian)
  static const String prosesJadi = 'PROSES_JADI'; // Hasil Akhir Perakitan

  // Sumber Mengurangi Stok
  static const String penjualan = 'PENJUALAN'; // Otomatis dari Kasir
  static const String itemKeluar = 'ITEM_KELUAR'; // Manual Out (Non-Penjualan)
  static const String perakitanBahan = 'PERAKITAN_BAHAN'; // Bahan Baku Terpakai

  // Penyesuaian Fisik (Audit)
  static const String opname = 'OPNAME'; // Stok Opname Selisih Fisik vs Program
}

// ===========================================================================
// DATA TRANSFER OBJECTS (DTO)
// ===========================================================================

/// DTO untuk Item Bahan Baku Perakitan
class AssemblyMaterialItem {
  final String rawProductId;
  final double quantityRequiredPerUnit; // Kuantitas bahan per 1 unit barang jadi

  AssemblyMaterialItem({
    required this.rawProductId,
    required this.quantityRequiredPerUnit,
  });
}

/// DTO Ringkasan Kartu Stok dengan Data Detail Produk & Rak
class StockCardItemData {
  final StockMutationData mutation;
  final String productName;
  final String productCode;
  final String? rackLocation;

  StockCardItemData({
    required this.mutation,
    required this.productName,
    required this.productCode,
    this.rackLocation,
  });
}

// ===========================================================================
// STOCK MUTATION DAO CLASS
// ===========================================================================

@DriftAccessor(tables: [Products, StockMutations])
class StockMutationDao extends DatabaseAccessor<LocalDatabase>
    with _$StockMutationDaoMixin {
  StockMutationDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. KARTU STOK & LAPORAN MUTASI (CHRONOLOGICAL HISTORY)
  // ===========================================================================

  /// Stream Kartu Stok Kronologis Per Item Produk (Menampilkan Jam & Menit)
  Stream<List<StockCardItemData>> watchKartuStok(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(stockMutations).join([
      innerJoin(products, products.id.equalsExp(stockMutations.productId)),
    ])
      ..where(stockMutations.productId.equals(productId));

    if (startDate != null && endDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query.where(stockMutations.date.isBetweenValues(start, end));
    }

    query.orderBy([
      OrderingTerm(expression: stockMutations.date, mode: OrderingMode.desc),
      OrderingTerm(expression: stockMutations.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final mutation = row.readTable(stockMutations);
        final product = row.readTable(products);

        return StockCardItemData(
          mutation: mutation,
          productName: product.name,
          productCode: product.code,
          rackLocation: product.rackLocation,
        );
      }).toList();
    });
  }

  /// Stream Laporan Mutasi Stok Seluruh Produk per Periode
  Stream<List<StockCardItemData>> watchAllStockMutations({
    DateTime? startDate,
    DateTime? endDate,
    String? mutationTypeFilter,
  }) {
    final query = select(stockMutations).join([
      innerJoin(products, products.id.equalsExp(stockMutations.productId)),
    ]);

    if (startDate != null && endDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query.where(stockMutations.date.isBetweenValues(start, end));
    }

    if (mutationTypeFilter != null && mutationTypeFilter.isNotEmpty) {
      query.where(stockMutations.type.equals(mutationTypeFilter));
    }

    query.orderBy([
      OrderingTerm(expression: stockMutations.date, mode: OrderingMode.desc),
      OrderingTerm(expression: stockMutations.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final mutation = row.readTable(stockMutations);
        final product = row.readTable(products);

        return StockCardItemData(
          mutation: mutation,
          productName: product.name,
          productCode: product.code,
          rackLocation: product.rackLocation,
        );
      }).toList();
    });
  }

  // ===========================================================================
  // 2. STOK OPNAME REAL-TIME (SOP SINKRONISASI FISIK VS PROGRAM)
  // ===========================================================================

  /// Eksekusi Stok Opname Real-Time
  /// SOP: Digunakan HANYA untuk mencocokkan selisih fisik vs program (bukan untuk tambah barang baru).
  Future<void> eksekusiStokOpname({
    required String productId,
    required double stokFisik,
    required String userId,
    required String keterangan, // Contoh: 'Rusak', 'Hilang', 'Selisih Hitung'
    String? newRackLocation, // Update nomor/posisi rak jika ada perpindahan
    DateTime? customDate, // Bisa diisi jam/tanggal mundur untuk koreksi minus
  }) async {
    await transaction(() async {
      final now = DateTime.now();
      final opnameDate = customDate ?? now;

      final product = await (select(products)
            ..where((p) => p.id.equals(productId)))
          .getSingleOrNull();

      if (product == null) {
        throw Exception('Produk tidak ditemukan.');
      }

      final stokSebelum = product.stock;
      final selisih = stokFisik - stokSebelum;

      // Jika tidak ada selisih dan lokasi rak tidak berubah, tidak perlu transaksi
      if (selisih == 0 && (newRackLocation == null || newRackLocation == product.rackLocation)) {
        return;
      }

      // 1. Update Master Produk (Stok Fisik Baru & Lokasi Rak)
      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stock: Value(stokFisik),
          rackLocation: Value(newRackLocation ?? product.rackLocation),
          updatedAt: Value(now),
        ),
      );

      // 2. Catat Log Mutasi Opname
      final refNo = 'OPN-${opnameDate.microsecondsSinceEpoch}';
      final mutId = 'MUT-${now.microsecondsSinceEpoch}';

      await into(stockMutations).insert(
        StockMutationsCompanion.insert(
          id: mutId,
          productId: productId,
          type: StockMutationType.opname,
          quantity: selisih, // Nilai positif jika lebih, negatif jika kurang
          stockBefore: stokSebelum,
          stockAfter: stokFisik,
          hppSnapshot: product.buyPrice,
          referenceNo: refNo,
          date: Value(opnameDate),
          userId: Value(userId),
          notes: Value('Opname Real-time: $keterangan (Selisih: ${selisih > 0 ? "+$selisih" : selisih})'),
          createdAt: Value(now),
          isSynced: const Value(false),
        ),
      );
    });
  }

  // ===========================================================================
  // 3. ITEM MASUK & ITEM KELUAR MANUAL (NON-PENJUALAN / NON-PEMBELIAN)
  // ===========================================================================

  /// Mencatat Mutasi Barang Masuk atau Barang Keluar Manual
  Future<void> catatMutasiManual({
    required String productId,
    required double qty,
    required String type, // StockMutationType.itemMasuk atau StockMutationType.itemKeluar
    required String refNo,
    required String userId,
    String? notes,
    String? rackLocation,
  }) async {
    if (type != StockMutationType.itemMasuk && type != StockMutationType.itemKeluar) {
      throw Exception('Tipe mutasi manual tidak valid. Gunakan ITEM_MASUK atau ITEM_KELUAR.');
    }

    await transaction(() async {
      final now = DateTime.now();

      final product = await (select(products)
            ..where((p) => p.id.equals(productId)))
          .getSingleOrNull();

      if (product == null) {
        throw Exception('Produk tidak ditemukan.');
      }

      final stokSebelum = product.stock;
      final qtyPerubahan = type == StockMutationType.itemMasuk ? qty.abs() : -qty.abs();
      final stokSesudah = stokSebelum + qtyPerubahan;

      // Cek proteksi stok minus jika barang keluar
      if (stokSesudah < 0 && !product.allowMinusStock) {
        throw Exception('Stok produk "${product.name}" tidak mencukupi (Sisa: $stokSebelum).');
      }

      // Update Stok Master Produk
      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stock: Value(stokSesudah),
          rackLocation: Value(rackLocation ?? product.rackLocation),
          updatedAt: Value(now),
        ),
      );

      // Insert Riwayat Mutasi
      await into(stockMutations).insert(
        StockMutationsCompanion.insert(
          id: 'MUT-${now.microsecondsSinceEpoch}',
          productId: productId,
          type: type,
          quantity: qtyPerubahan,
          stockBefore: stokSebelum,
          stockAfter: stokSesudah,
          hppSnapshot: product.buyPrice,
          referenceNo: refNo,
          date: Value(now),
          userId: Value(userId),
          notes: Value(notes ?? (type == StockMutationType.itemMasuk ? 'Input Barang Masuk Manual' : 'Barang Keluar Non-Penjualan')),
          createdAt: Value(now),
          isSynced: const Value(false),
        ),
      );
    });
  }

  // ===========================================================================
  // 4. PROSES PERAKITAN & PROSES JADI (ASSEMBLY SYSTEM)
  // ===========================================================================

  /// Eksekusi Proses Perakitan Paket/Bundling secara Atomics:
  /// - Mengurangi stok Bahan Baku (PROSES_PERAKITAN_BAHAN)
  /// - Menambah stok Barang Jadi (PROSES_JADI)
  Future<void> eksekusiPerakitanProduk({
    required String finishedProductId,
    required double finishedQtyToProduce,
    required List<AssemblyMaterialItem> materials,
    required String userId,
    String? notes,
  }) async {
    if (finishedQtyToProduce <= 0) {
      throw Exception('Jumlah produksi barang jadi harus lebih dari 0.');
    }

    await transaction(() async {
      final now = DateTime.now();
      final refNo = 'ASM-${now.microsecondsSinceEpoch}';

      // 1. Kurangi Stok Masing-Masing Bahan Baku
      for (final mat in materials) {
        final rawProduct = await (select(products)
              ..where((p) => p.id.equals(mat.rawProductId)))
            .getSingleOrNull();

        if (rawProduct == null) {
          throw Exception('Bahan baku dengan ID ${mat.rawProductId} tidak ditemukan.');
        }

        final totalNeeded = mat.quantityRequiredPerUnit * finishedQtyToProduce;
        final rawStokSebelum = rawProduct.stock;
        final rawStokSesudah = rawStokSebelum - totalNeeded;

        if (rawStokSesudah < 0 && !rawProduct.allowMinusStock) {
          throw Exception('Stok bahan baku "${rawProduct.name}" tidak cukup (Dibutuhkan: $totalNeeded, Sisa: $rawStokSebelum).');
        }

        // Update Stok Bahan Baku
        await (update(products)..where((p) => p.id.equals(mat.rawProductId))).write(
          ProductsCompanion(
            stock: Value(rawStokSesudah),
            updatedAt: Value(now),
          ),
        );

        // Mutasi Pengurangan Bahan Baku
        await into(stockMutations).insert(
          StockMutationsCompanion.insert(
            id: 'MUT-RAW-${now.microsecondsSinceEpoch}',
            productId: mat.rawProductId,
            type: StockMutationType.perakitanBahan,
            quantity: -totalNeeded,
            stockBefore: rawStokSebelum,
            stockAfter: rawStokSesudah,
            hppSnapshot: rawProduct.buyPrice,
            referenceNo: refNo,
            date: Value(now),
            userId: Value(userId),
            notes: Value('Penggunaan Bahan Baku untuk Perakitan Ref: $refNo'),
            createdAt: Value(now),
            isSynced: const Value(false),
          ),
        );
      }

      // 2. Tambah Stok Barang Jadi (Hasil Akhir Perakitan)
      final finishedProduct = await (select(products)
            ..where((p) => p.id.equals(finishedProductId)))
          .getSingleOrNull();

      if (finishedProduct == null) {
        throw Exception('Produk Barang Jadi tidak ditemukan.');
      }

      final finStokSebelum = finishedProduct.stock;
      final finStokSesudah = finStokSebelum + finishedQtyToProduce;

      await (update(products)..where((p) => p.id.equals(finishedProductId))).write(
        ProductsCompanion(
          stock: Value(finStokSesudah),
          updatedAt: Value(now),
        ),
      );

      // Mutasi Penambahan Barang Jadi
      await into(stockMutations).insert(
        StockMutationsCompanion.insert(
          id: 'MUT-FIN-${now.microsecondsSinceEpoch}',
          productId: finishedProductId,
          type: StockMutationType.prosesJadi,
          quantity: finishedQtyToProduce,
          stockBefore: finStokSebelum,
          stockAfter: finStokSesudah,
          hppSnapshot: finishedProduct.buyPrice,
          referenceNo: refNo,
          date: Value(now),
          userId: Value(userId),
          notes: Value(notes ?? 'Hasil Proses Perakitan Produk'),
          createdAt: Value(now),
          isSynced: const Value(false),
        ),
      );
    });
  }

  // ===========================================================================
  // 5. UPDATE LOKASI RAK / NOMOR RAK PRODUK
  // ===========================================================================

  /// Memperbarui Posisi Nomor Rak/Gudang Item Tanpa Mengubah Stok
  Future<void> updateLokasiRak(String productId, String newRackLocation) async {
    final now = DateTime.now();
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        rackLocation: Value(newRackLocation),
        updatedAt: Value(now),
      ),
    );
  }

  // ===========================================================================
  // 6. PROSES PERBAIKAN SALDO (RECALCULATE CHRONOLOGICAL STOCK HISTORY)
  // ===========================================================================

  /// SOP C.3: Rekalkulasi Ulang Saldo Kronologis Kartu Stok untuk Memperbaiki Minus akibat kesalahan Urutan Jam/Tanggal Transaksi
  Future<void> prosesPerbaikanSaldo(String productId) async {
    await transaction(() async {
      // 1. Ambil seluruh mutasi produk ini diurutkan dari TANGGAL TERLAMA -> TERBARU
      final history = await (select(stockMutations)
            ..where((m) => m.productId.equals(productId))
            ..orderBy([
              (m) => OrderingTerm(expression: m.date, mode: OrderingMode.asc),
              (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.asc),
            ]))
          .get();

      if (history.isEmpty) return;

      double runningStock = 0.0;

      // 2. Hitung ulang running stock dan update baris mutasi
      for (int i = 0; i < history.length; i++) {
        final mut = history[i];

        // Jika tipe mutasi adalah OPNAME, running stock dipaksa mengikuti penyesuaian fisik opname
        double stockBefore = runningStock;
        double stockAfter;

        if (mut.type == StockMutationType.opname) {
          // Mutasi opname menyimpan selisih pada kolom quantity
          stockAfter = stockBefore + mut.quantity;
        } else {
          stockAfter = stockBefore + mut.quantity;
        }

        // Update record mutasi
        await (update(stockMutations)..where((m) => m.id.equals(mut.id))).write(
          StockMutationsCompanion(
            stockBefore: Value(stockBefore),
            stockAfter: Value(stockAfter),
          ),
        );

        runningStock = stockAfter;
      }

      // 3. Set Stok Akhir di Tabel Master Product sesuai running stock terakhir
      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stock: Value(runningStock),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}

// ===========================================================================
// PROVIDERS RIVERPOD
// ===========================================================================

final stockMutationDaoProvider = Provider<StockMutationDao>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return StockMutationDao(db);
});

/// StreamProvider Kartu Stok Per Produk
final kartuStokStreamProvider =
    StreamProvider.family<List<StockCardItemData>, String>((ref, productId) {
  final dao = ref.watch(stockMutationDaoProvider);
  return dao.watchKartuStok(productId);
});

/// StreamProvider Laporan Seluruh Mutasi Stok
final allStockMutationsStreamProvider =
    StreamProvider<List<StockCardItemData>>((ref) {
  final dao = ref.watch(stockMutationDaoProvider);
  return dao.watchAllStockMutations();
});

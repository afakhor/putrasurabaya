import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/supplier_table.dart';
import 'package:ud_putra_kasir/core/database/tables/purchase_table.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'payables_dao.g.dart';

class PayableWithSupplier {
  final PayableData payable;
  final SupplierData supplier;
  PayableWithSupplier({required this.payable, required this.supplier});
}
class PurchaseWithSupplier {
  final PayableData purchase;
  final SupplierData? supplier;
  PurchaseWithSupplier({required this.purchase, this.supplier});
}

@DriftAccessor(tables: [Payables, DebtPayments, Suppliers, Purchases, PurchaseItems])
class PayablesDao extends DatabaseAccessor<LocalDatabase> with _$PayablesDaoMixin {
  PayablesDao(LocalDatabase db) : super(db);

  // ========== PEMBELIAN - LEWAT ORCHESTRATOR ==========
  Future<String> insertPurchaseTransaction({
    required PurchasesCompanion dataPembelian,
    required List<PurchaseItemsCompanion> itemPembelian,
  }) async {
    await db.prosesPembelianPenyimpanan(dataPembelian: dataPembelian, itemPembelian: itemPembelian);
    return dataPembelian.id.value;
  }

  // ========== QUERY HUTANG ==========
  Stream<List<PayableData>> watchActivePayables() => (select(payables)..where((tbl) => tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))..orderBy([(tbl) => OrderingTerm.asc(tbl.dueDate)])).watch();
  Stream<List<PayableData>> watchUnpaidPayables() => watchActivePayables();
  Stream<List<PayableData>> watchOverduePayables({DateTime? dateLimit}) {
    final limit = dateLimit ?? DateTime.now();
    return (select(payables)..where((tbl) => tbl.dueDate.isSmallerOrEqualValue(limit) & tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))..orderBy([(tbl) => OrderingTerm.asc(tbl.dueDate)])).watch();
  }
  Stream<List<PayableData>> watchPayablesBySupplier(String supplierId) => (select(payables)..where((tbl) => tbl.supplierId.equals(supplierId))..orderBy([(tbl) => OrderingTerm.desc(tbl.dueDate)])).watch();
  Stream<PayableData?> watchPayableById(String id) => (select(payables)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  Future<PayableData?> getPayableById(String id) => (select(payables)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  
  Stream<List<PayableWithSupplier>> watchActivePayablesWithSupplier() {
    final q = select(payables).join([innerJoin(suppliers, suppliers.id.equalsExp(payables.supplierId))])..where(payables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))..orderBy([OrderingTerm.asc(payables.dueDate)]);
    return q.watch().map((rows) => rows.map((r) => PayableWithSupplier(payable: r.readTable(payables), supplier: r.readTable(suppliers))).toList());
  }
  Future<double> getTotalRemainingPayables() async {
    final sumExp = payables.remainingAmount.sum();
    final row = await (selectOnly(payables)..addColumns([sumExp])..where(payables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))).getSingleOrNull();
    return row?.read(sumExp) ?? 0.0;
  }
  Future<PurchaseWithSupplier?> getPurchaseById(String payableId) async {
    final p = await (select(payables)..where((t) => t.id.equals(payableId))).getSingleOrNull();
    if (p == null) return null;
    final s = await (select(suppliers)..where((s) => s.id.equals(p.supplierId))).getSingleOrNull();
    return PurchaseWithSupplier(purchase: p, supplier: s);
  }

  // ========== BAYAR HUTANG ==========
  Future<bool> bayarAngsuranHutang({required String payableId, required double nominalBayar, required String paymentMethod, String? notes}) async {
    if (nominalBayar <= 0) throw Exception('Nominal tidak valid');
    return transaction(() async {
      final item = await (select(payables)..where((tbl) => tbl.id.equals(payableId))).getSingleOrNull();
      if (item == null) throw Exception('Hutang tidak ditemukan');
      if (item.remainingAmount <= 0) throw Exception('Sudah lunas');
      final actualBayar = nominalBayar > item.remainingAmount ? item.remainingAmount : nominalBayar;
      final newPaid = item.paidAmount + actualBayar;
      final newRemaining = item.totalAmount - newPaid;
      final newStatus = DebtStatus.tentukanStatus(newRemaining, actualBayar);
      await (update(payables)..where((tbl) => tbl.id.equals(payableId))).write(PayablesCompanion(paidAmount: Value(newPaid), remainingAmount: Value(newRemaining < 0 ? 0 : newRemaining), status: Value(newStatus), isSynced: const Value(false), updatedAt: Value(DateTime.now())));
      await into(debtPayments).insert(DebtPaymentsCompanion.insert(id: 'PAY-AP-${DateTime.now().millisecondsSinceEpoch}', refId: payableId, type: 'payable', userId: 'system', amount: actualBayar, paymentMethod: Value(paymentMethod), notes: Value(notes ?? 'Angsuran Hutang'), isSynced: const Value(false)));
      return true;
    });
  }
  Future<List<DebtPaymentData>> getPaymentHistory(String payableId) => (select(debtPayments)..where((tbl) => tbl.refId.equals(payableId) & tbl.type.equals('payable'))..orderBy([(tbl) => OrderingTerm.desc(tbl.paymentDate)])).get();
  Stream<List<DebtPaymentData>> watchPaymentHistory(String payableId) => (select(debtPayments)..where((tbl) => tbl.refId.equals(payableId) & tbl.type.equals('payable'))..orderBy([(tbl) => OrderingTerm.desc(tbl.paymentDate)])).watch();
}

final payablesDaoProvider = Provider<PayablesDao>((ref) => PayablesDao(ref.watch(localDatabaseProvider)));
final unpaidPayablesStreamProvider = StreamProvider<List<PayableData>>((ref) => ref.watch(payablesDaoProvider).watchUnpaidPayables());
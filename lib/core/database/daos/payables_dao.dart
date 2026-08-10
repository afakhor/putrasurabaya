import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/supplier_table.dart';
import 'package:ud_putra_kasir/core/database/tables/purchase_table.dart';
import 'package:ud_putra_kasir/core/database/tables/stock_mutation_table.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'payables_dao.g.dart';

class PayableWithSupplier {
  final PayableData payable;
  final SupplierData supplier;
  PayableWithSupplier({required this.payable, required this.supplier});
}

// === IPOS LOGIC TAMBAHAN - TIDAK UBAH CLASS LAMA ===
enum PayableStatus { lunas, belumJatuhTempo, dueSoon, overdue }

extension PayableX on PayableData {
  int get daysOverdue {
    if (dueDate == null) return -999;
    return DateTime.now().difference(dueDate!).inDays;
  }
  PayableStatus get payableStatus {
    if (remainingAmount <= 0) return PayableStatus.lunas;
    if (daysOverdue > 0) return PayableStatus.overdue;
    if (daysOverdue >= -3) return PayableStatus.dueSoon;
    return PayableStatus.belumJatuhTempo;
  }
}

extension DateX on DateTime {
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;
}

@DriftAccessor(tables: [Payables, DebtPayments, Suppliers, Purchases, PurchaseItems, StockMutations])
class PayablesDao extends DatabaseAccessor<LocalDatabase> with _$PayablesDaoMixin {
  PayablesDao(LocalDatabase db) : super(db);

  Future<String> insertPurchaseTransaction({
    required PurchasesCompanion dataPembelian,
    required List<PurchaseItemsCompanion> itemPembelian,
  }) async {
    await db.prosesPembelianPenyimpanan(dataPembelian: dataPembelian, itemPembelian: itemPembelian);
    return dataPembelian.id.value;
  }

  Stream<List<PayableData>> watchActivePayables() => (select(payables)..where((tbl) => tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))..orderBy([(tbl) => OrderingTerm.asc(tbl.dueDate)])).watch();
  Stream<List<PayableData>> watchUnpaidPayables() => watchActivePayables();

  Stream<List<PayableWithSupplier>> watchActivePayablesWithSupplier() {
    final q = select(payables).join([innerJoin(suppliers, suppliers.id.equalsExp(payables.supplierId))])
     ..where(payables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))
     ..orderBy([OrderingTerm.asc(payables.dueDate)]);
    return q.watch().map((rows) => rows.map((r) => PayableWithSupplier(payable: r.readTable(payables), supplier: r.readTable(suppliers))).toList());
  }

  Future<bool> bayarAngsuranHutang({required String payableId, required double nominalBayar, required String paymentMethod, String? notes}) async {
    if (nominalBayar <= 0) throw Exception('Nominal tidak valid');
    return transaction(() async {
      final item = await (select(payables)..where((tbl) => tbl.id.equals(payableId))).getSingleOrNull();
      if (item == null) throw Exception('Hutang tidak ditemukan');
      final actualBayar = nominalBayar > item.remainingAmount? item.remainingAmount : nominalBayar;
      final newPaid = item.paidAmount + actualBayar;
      final newRemaining = item.totalAmount - newPaid;
      final newStatus = DebtStatus.tentukanStatus(newRemaining, actualBayar);
      await (update(payables)..where((tbl) => tbl.id.equals(payableId))).write(
        PayablesCompanion(paidAmount: Value(newPaid), remainingAmount: Value(newRemaining < 0? 0 : newRemaining), status: Value(newStatus), isSynced: const Value(false), updatedAt: Value(DateTime.now()))
      );
      await into(debtPayments).insert(DebtPaymentsCompanion.insert(
        id: 'PAY-AP-${DateTime.now().millisecondsSinceEpoch}',
        refId: Value(payableId),
        type: Value('payable'),
        userId: const Value('system'),
        amount: Value(actualBayar),
        paymentMethod: Value(paymentMethod),
        notes: Value(notes?? 'Angsuran Hutang'),
        isSynced: const Value(false),
        paymentDate: Value(DateTime.now())
      ));
      return true;
    });
  }

  Stream<List<DebtPaymentData>> watchPaymentHistory(String payableId) =>
    (select(debtPayments)..where((tbl) => tbl.refId.equals(payableId) & tbl.type.equals('payable'))..orderBy([(tbl) => OrderingTerm.desc(tbl.paymentDate)])).watch();

  // ==================== TAMBAHAN IPOS LOGIC - TIDAK UBAH YANG LAMA ====================
  List<PayableData> getUrgentPayables(List<PayableData> all) {
    return all.where((p) => p.remainingAmount > 0).toList()
     ..sort((a,b) => (a.dueDate??DateTime.now()).compareTo(b.dueDate??DateTime.now()));
  }

  Future<Map<String, dynamic>> payableSummary() async {
    final all = await (select(payables)..where((t)=> t.remainingAmount.isBiggerThanValue(0))).get();
    final outstanding = all.where((p) => p.remainingAmount > 0);
    final now = DateTime.now();
    double sumWhere(bool Function(PayableData) f) => outstanding.where(f).fold(0.0, (s,e)=> s+e.remainingAmount);
    return {
      'totalOutstanding': outstanding.fold(0.0, (s,e)=> s+e.remainingAmount),
      'totalOverdue': outstanding.where((p)=> p.payableStatus == PayableStatus.overdue).fold(0.0, (s,e)=> s+e.remainingAmount),
      'dueToday': outstanding.where((p)=> p.dueDate!=null && p.dueDate!.isSameDay(now)).toList(),
      'dueNext3Days': outstanding.where((p)=> p.payableStatus == PayableStatus.dueSoon).toList(),
      'aging_0_30': sumWhere((p)=> p.daysOverdue >=0 && p.daysOverdue <=30),
      'aging_31_60': sumWhere((p)=> p.daysOverdue >30 && p.daysOverdue <=60),
      'aging_60plus': sumWhere((p)=> p.daysOverdue >60),
      'top5Supplier': _groupBySupplier(outstanding.toList()),
      'countOverdue7': outstanding.where((p)=> p.daysOverdue >7).length,
    };
  }

  Map<String, double> _groupBySupplier(List<PayableData> data) {
    final map = <String,double>{};
    for(final p in data){
      final key = p.supplierName?? p.supplierId?? 'Unknown';
      map[key] = (map[key]??0)+p.remainingAmount;
    }
    final sorted = map.entries.toList()..sort((a,b)=> b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  Future<bool> isPayableFiktif(PayableData p) async {
    final invNo = p.purchaseId?? p.id;
    final mutasi = await (select(stockMutations)..where((m)=> m.referenceNo.equals(invNo) | m.referenceId.equals(invNo))).get();
    return mutasi.isEmpty;
  }

  Future<List<String>> getLevel1MerahAlerts() async {
    final all = await (select(payables)..where((t)=> t.remainingAmount.isBiggerThanValue(0))).get();
    final alerts = <String>[];
    for(final p in all){
      if(p.remainingAmount >0 && p.daysOverdue >7){
        alerts.add('HUTANG OVERDUE: ${p.supplierName} - ${p.purchaseId} Telat ${p.daysOverdue} hari Rp ${p.remainingAmount}');
      }
    }
    return alerts;
  }
}

final payablesDaoProvider = Provider<PayablesDao>((ref) => PayablesDao(ref.watch(localDatabaseProvider)));
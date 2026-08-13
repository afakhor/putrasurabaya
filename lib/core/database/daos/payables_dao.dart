import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/supplier_table.dart';
import 'package:ud_putra_kasir/core/database/tables/purchase_table.dart';
import 'package:ud_putra_kasir/core/database/tables/stock_mutation_table.dart';
import 'package:ud_putra_kasir/core/database/tables/audit_log_table.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';

part 'payables_dao.g.dart';

class PayableWithSupplier {
  final PayableData payable;
  final SupplierData supplier;
  PayableWithSupplier({required this.payable, required this.supplier});
}
enum PayableStatus { lunas, belumJatuhTempo, dueSoon, overdue }
extension PayableX on PayableData {
  int get daysOverdue => dueDate==null? -999 : DateTime.now().difference(dueDate!).inDays;
  PayableStatus get payableStatus {
    if (remainingAmount <= 0) return PayableStatus.lunas;
    if (daysOverdue > 0) return PayableStatus.overdue;
    if (daysOverdue >= -3) return PayableStatus.dueSoon;
    return PayableStatus.belumJatuhTempo;
  }
}
extension DateX on DateTime {
  bool isSameDay(DateTime other) => year==other.year && month==other.month && day==other.day;
}

@DriftAccessor(tables: [Payables, DebtPayments, Suppliers, Purchases, PurchaseItems, StockMutations, AuditLogs, FraudAlerts])
class PayablesDao extends DatabaseAccessor<LocalDatabase> with _$PayablesDaoMixin {
  PayablesDao(LocalDatabase db) : super(db);

  Future<List<PayableData>> getAllPayables() => select(payables).get();
  Stream<List<PayableData>> watchAll() => select(payables).watch();
  Future<double> getTotalActivePayableAmount() async {
    final all = await select(payables).get();
    return all.where((e)=> e.remainingAmount>0).fold<double>(0, (p,e)=> p+e.remainingAmount);
  }
  Future<List<PayableData>> getByDateRange(DateTime start, DateTime end) =>
    (select(payables)..where((t)=> t.createdAt.isBetweenValues(start, end))).get();

  Future<String> insertPurchaseTransaction({required PurchasesCompanion dataPembelian, required List<PurchaseItemsCompanion> itemPembelian}) async {
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
      final oldSisa = item.remainingAmount;
      await (update(payables)..where((tbl) => tbl.id.equals(payableId))).write(
        PayablesCompanion(paidAmount: Value(newPaid), remainingAmount: Value(newRemaining < 0? 0 : newRemaining), status: Value(newStatus), isSynced: const Value(false), updatedAt: Value(DateTime.now()))
      );
      await into(debtPayments).insert(DebtPaymentsCompanion.insert(
        id: 'PAY-AP-${DateTime.now().millisecondsSinceEpoch}',
        refId: Value(payableId), type: Value('payable'), userId: const Value('system'),
        amount: Value(actualBayar), paymentMethod: Value(paymentMethod), notes: Value(notes?? 'Angsuran Hutang'),
        isSynced: const Value(false), paymentDate: Value(DateTime.now())
      ));
      final logId = 'LOG-PAY-${DateTime.now().microsecondsSinceEpoch}';
      await into(auditLogs).insert(AuditLogsCompanion.insert(
        id: logId, userId: 'owner-01', userRole: const Value('owner'), actionType: 'BAYAR_HUTANG',
        tblName: const Value('payables'), referenceId: Value(item.purchaseId?? payableId), recordId: Value(payableId),
        oldValue: Value('{"sisa_lama":$oldSisa}'), newValue: Value('{"bayar":$actualBayar,"sisa_baru":$newRemaining}'),
        description: Value('BAYAR HUTANG ${item.purchaseId} Supplier ${item.supplierName} Bayar $actualBayar Sisa $oldSisa -> $newRemaining via $paymentMethod ${notes??""}'),
      ));
      if(item.daysOverdue > 7){
        await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
          id: 'ALT-PAY-${DateTime.now().microsecondsSinceEpoch}', userId: 'owner-01', alertType: 'bayar_overdue',
          title: Value('BAYAR OVERDUE ${item.purchaseId}'), description: Value('Hutang ${item.purchaseId} telat ${item.daysOverdue} hari baru dibayar $actualBayar'),
          detailAnalysis: Value('Hutang ${item.purchaseId} supplier ${item.supplierName} telat ${item.daysOverdue} hari sisa $oldSisa dibayar $actualBayar via $paymentMethod'),
          fraudCategory: Value('hutang_overdue'), severity: Value('kuning'), auditLogId: Value(logId),
        ));
      }
      return true;
    });
  }
  Stream<List<DebtPaymentData>> watchPaymentHistory(String payableId) =>
    (select(debtPayments)..where((tbl) => tbl.refId.equals(payableId) & tbl.type.equals('payable'))..orderBy([(tbl) => OrderingTerm.desc(tbl.paymentDate)])).watch();
  List<PayableData> getUrgentPayables(List<PayableData> all) => all.where((p) => p.remainingAmount > 0).toList()..sort((a,b) => (a.dueDate?? DateTime.now()).compareTo(b.dueDate?? DateTime.now()));
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
      'countOverdue7': outstanding.where((p)=> p.daysOverdue >7).length,
    };
  }

  // ====== TARUH DI SINI BOS, DI DALAM CLASS SEBELUM TUTUP ======
  Future<List<String>> getLevel1MerahAlerts() async {
    final all = await (select(payables)..where((t)=> t.remainingAmount.isBiggerThanValue(0))).get();
    final alerts=<String>[];
    for(final p in all){
      final days = p.dueDate==null? -999 : DateTime.now().difference(p.dueDate!).inDays;
      if(p.remainingAmount>0 && days>7){
        alerts.add('HUTANG OVERDUE: ${p.supplierName} - ${p.purchaseId} Telat $days hari Rp ${p.remainingAmount}');
      }
    }
    return alerts;
  }

Future<bool> isPayableFiktif(PayableData p) async {
  final invNo = p.purchaseId?? p.id;
  final mutasi = await (select(stockMutations)..where((m)=> m.referenceNo.equals(invNo) | m.referenceId.equals(invNo))).get();
  if(mutasi.isEmpty){
    final logId = 'LOG-FIKTIF-${DateTime.now().microsecondsSinceEpoch}';
    await into(auditLogs).insert(AuditLogsCompanion.insert(
      id: logId, userId: 'SYSTEM', userRole: const Value('system'), actionType: 'HUTANG_FIKTIF_DETECT',
      tblName: const Value('payables'), referenceId: Value(invNo), recordId: Value(p.id),
      oldValue: Value('{"total":${p.totalAmount}}'), newValue: Value('{"mutasi":0}'),
      description: Value('DETEKSI HUTANG FIKTIF ${p.purchaseId}'),
    ));
    await into(fraudAlerts).insert(FraudAlertsCompanion.insert(
      id: 'ALT-FIKTIF-${DateTime.now().microsecondsSinceEpoch}', userId: 'SYSTEM', alertType: 'hutang_fiktif',
      title: Value('HUTANG FIKTIF ${p.purchaseId}'), description: Value('Payable ${p.id} tanpa mutasi $invNo'),
      detailAnalysis: Value('Tanpa StockMutations ref $invNo'), fraudCategory: Value('hutang_fiktif'), severity: Value('merah'), auditLogId: Value(logId),
    ));
    return true;
  }
  return false;
}

} // <-- KURUNG TUTUP CLASS DI SINI

final payablesDaoProvider = Provider<PayablesDao>((ref) => PayablesDao(ref.watch(localDatabaseProvider)));
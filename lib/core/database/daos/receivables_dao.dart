import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/constant/constant_debt_status.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/finance_table.dart';
import 'package:ud_putra_kasir/core/database/tables/customer_table.dart';
part 'receivables_dao.g.dart';

class ReceivableWithCustomer {
  final ReceivableData receivable;
  final CustomerData? customer;
  ReceivableWithCustomer({required this.receivable, this.customer});
}

@DriftAccessor(tables: [Receivables, Customers, DebtPayments])
class ReceivablesDao extends DatabaseAccessor<LocalDatabase> with _$ReceivablesDaoMixin {
  ReceivablesDao(LocalDatabase db) : super(db);

  // ===== UNTUK REPORTS REAL TIME - DARI AWAL SAMPAI AKHIR =====
  Future<List<ReceivableData>> getAllReceivables() => select(receivables).get();
  Stream<List<ReceivableData>> watchAll() => select(receivables).watch();
  Future<List<ReceivableData>> getByDateRange(DateTime start, DateTime end) =>
    (select(receivables)..where((t)=> t.createdAt.isBetweenValues(start, end))).get();

  Stream<List<ReceivableWithCustomer>> watchActiveReceivables() {
    final query = select(receivables).join([leftOuterJoin(customers, customers.id.equalsExp(receivables.customerId))])..where(receivables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))..orderBy([OrderingTerm.asc(receivables.dueDate)]);
    return query.watch().map((rows) => rows.map((row) => ReceivableWithCustomer(receivable: row.readTable(receivables), customer: row.readTableOrNull(customers))).toList());
  }
  Stream<List<ReceivableWithCustomer>> searchReceivables(String queryText) {
    if (queryText.trim().isEmpty) return watchActiveReceivables();
    final cleanQuery = '%${queryText.trim().toLowerCase()}%';
    final query = select(receivables).join([leftOuterJoin(customers, customers.id.equalsExp(receivables.customerId))])..where(receivables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]) & (customers.name.lower().like(cleanQuery) | receivables.transactionId.lower().like(cleanQuery) | receivables.invoiceNo.lower().like(cleanQuery)))..orderBy([OrderingTerm.asc(receivables.dueDate)]);
    return query.watch().map((rows) => rows.map((row) => ReceivableWithCustomer(receivable: row.readTable(receivables), customer: row.readTableOrNull(customers))).toList());
  }
  Stream<List<ReceivableData>> watchReceivablesByCustomer(String customerId) => (select(receivables)..where((tbl) => tbl.customerId.equals(customerId))..orderBy([(tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.desc)])).watch();
  Stream<List<ReceivableWithCustomer>> watchOverdueReceivables({DateTime? dateLimit}) {
    final limit = dateLimit ?? DateTime.now();
    final query = select(receivables).join([leftOuterJoin(customers, customers.id.equalsExp(receivables.customerId))])..where(receivables.dueDate.isSmallerOrEqualValue(limit) & receivables.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]))..orderBy([OrderingTerm.asc(receivables.dueDate)]);
    return query.watch().map((rows) => rows.map((row) => ReceivableWithCustomer(receivable: row.readTable(receivables), customer: row.readTableOrNull(customers))).toList());
  }
  Future<double> getTotalActiveReceivableAmount() async {
    final query = select(receivables)..where((tbl) => tbl.status.isNotIn([DebtStatus.paid, DebtStatus.lunas]));
    final list = await query.get();
    return list.fold<double>(0.0, (sum, item) => sum + item.remainingAmount);
  }
  Future<List<ReceivableData>> getTop10Overdue() => (select(receivables)..where((t)=>t.remainingAmount.isBiggerThanValue(0))..orderBy([(t)=>OrderingTerm.desc(t.umurNgendap)])..limit(10)).get();
  Future<List<ReceivableData>> getJtHariIni() {
    final today=DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tomorrow=today.add(const Duration(days:1));
    return (select(receivables)..where((t)=>t.dueDate.isBetweenValues(today, tomorrow) & t.remainingAmount.isBiggerThanValue(0))).get();
  }
  Future<void> refreshUmurNgendapAll() async {
    await customStatement('UPDATE receivables SET umur_ngendap = CAST((julianday("now") - julianday(invoice_date)) AS INTEGER), status_ngendap_warna = CASE WHEN CAST((julianday("now") - julianday(invoice_date)) AS INTEGER) > 90 THEN "MERAH" WHEN CAST((julianday("now") - julianday(invoice_date)) AS INTEGER) > 60 THEN "ORANGE" WHEN CAST((julianday("now") - julianday(invoice_date)) AS INTEGER) > 30 THEN "KUNING" ELSE "HIJAU" END WHERE remaining_amount > 0');
  }
  Future<Map<String,double>> getAgingBucket() async {
    final all=await (select(receivables)..where((t)=>t.remainingAmount.isBiggerThanValue(0))).get();
    double b0_7=0,b8_30=0,b31_60=0,b60plus=0;
    final now=DateTime.now();
    for(final r in all){
      if(r.dueDate==null) continue;
      final umur=now.difference(r.dueDate!).inDays;
      if(umur<=7) b0_7+=r.remainingAmount;
      else if(umur<=30) b8_30+=r.remainingAmount;
      else if(umur<=60) b31_60+=r.remainingAmount;
      else b60plus+=r.remainingAmount;
    }
    return {'0-7':b0_7,'8-30':b8_30,'31-60':b31_60,'>60':b60plus};
  }
  Future<void> catatPiutangBaru({required String transactionId, required String customerId, required double totalAmount, required double dpAmount, required DateTime dueDate, String paymentMethod='CASH', String? salesId, String? userId, String kenapaNgendap='MACET', DateTime? invoiceDate}) async {
    final now=DateTime.now();
    final sisaPiutang=totalAmount-dpAmount;
    final actualSisa=sisaPiutang<0?0.0:sisaPiutang;
    final status=DebtStatus.tentukanStatus(actualSisa, dpAmount);
    final receivableId='RC-${now.microsecondsSinceEpoch}';
    final umur=now.difference(invoiceDate??now).inDays;
    await transaction(() async {
      await into(receivables).insert(ReceivablesCompanion.insert(
        id: receivableId, transactionId: Value(transactionId), invoiceNo: Value(transactionId), customerId: Value(customerId), customerIdRef: Value(customerId), salesId: Value(salesId), salesmanId: Value(salesId), customerName: Value(''), totalAmount: Value(totalAmount), paidAmount: Value(dpAmount), remainingAmount: Value(actualSisa), amount: Value(totalAmount), remaining: Value(actualSisa), dueDate: Value(dueDate), invoiceDate: Value(invoiceDate??now), status: Value(status), kenapaNgendap: Value(kenapaNgendap), umurNgendap: Value(umur>0?umur:0), statusNgendapWarna: Value(umur>90?'MERAH':umur>60?'ORANGE':umur>30?'KUNING':'HIJAU'), isSynced: const Value(false), createdAt: Value(now), updatedAt: Value(now),
      ));
      final customer=await (select(customers)..where((tbl)=>tbl.id.equals(customerId))).getSingleOrNull();
      if(customer!=null){
        final newDebt=customer.sisaHutang+actualSisa;
        await (update(customers)..where((tbl)=>tbl.id.equals(customerId))).write(CustomersCompanion(sisaHutang: Value(newDebt), isSynced: const Value(false), updatedAt: Value(now)));
      }
      if(dpAmount>0){
        await into(debtPayments).insert(DebtPaymentsCompanion.insert(id: 'PAY-AR-${now.microsecondsSinceEpoch}', refId: Value(receivableId), type: Value('receivable'), userId: Value(userId??'SYSTEM'), amount: Value(dpAmount), paymentMethod: Value(paymentMethod), notes: const Value('Uang Muka / DP'), isSynced: const Value(false), paymentDate: Value(now)));
      }
    });
  }
  Future<bool> bayarAngsuranPiutang({required String receivableId, required double nominalBayar, required String paymentMethod, required String userId, String? proofImage, String? notes}) async {
    if(nominalBayar<=0) throw Exception('Nominal tidak valid');
    return transaction(() async {
      final now=DateTime.now();
      final item=await (select(receivables)..where((tbl)=>tbl.id.equals(receivableId))).getSingleOrNull();
      if(item==null) throw Exception('Piutang tidak ditemukan');
      if(item.remainingAmount<=0) throw Exception('Sudah lunas');
      final actualBayar=nominalBayar>item.remainingAmount?item.remainingAmount:nominalBayar;
      final newPaid=item.paidAmount+actualBayar;
      final newRemaining=item.totalAmount-newPaid;
      final actualNewRemaining=newRemaining<0?0.0:newRemaining;
      final newStatus=DebtStatus.tentukanStatus(actualNewRemaining, actualBayar);
      await (update(receivables)..where((tbl)=>tbl.id.equals(receivableId))).write(ReceivablesCompanion(paidAmount: Value(newPaid), remainingAmount: Value(actualNewRemaining), remaining: Value(actualNewRemaining), status: Value(newStatus), isSynced: const Value(false), updatedAt: Value(now)));
      if(item.customerId!=null){
        final customer=await (select(customers)..where((tbl)=>tbl.id.equals(item.customerId!))).getSingleOrNull();
        if(customer!=null){
          final sisa=customer.sisaHutang-actualBayar;
          await (update(customers)..where((tbl)=>tbl.id.equals(item.customerId!))).write(CustomersCompanion(sisaHutang: Value(sisa<0?0.0:sisa), isSynced: const Value(false), updatedAt: Value(now)));
        }
      }
      await into(debtPayments).insert(DebtPaymentsCompanion.insert(id: 'PAY-AR-${now.microsecondsSinceEpoch}', refId: Value(receivableId), type: Value('receivable'), userId: Value(userId), amount: Value(actualBayar), paymentMethod: Value(paymentMethod), proofImage: Value(proofImage), notes: Value(notes??(newStatus==DebtStatus.paid||newStatus==DebtStatus.lunas?'Pelunasan':'Angsuran')), isSynced: const Value(false), paymentDate: Value(now)));
      return true;
    });
  }
  Future<List<DebtPaymentData>> getPaymentHistory(String receivableId){
    return (select(debtPayments)..where((tbl)=>tbl.refId.equals(receivableId)&tbl.type.equals('receivable'))..orderBy([(tbl)=>OrderingTerm(expression: tbl.paymentDate, mode: OrderingMode.desc)])).get();
  }
}

final receivablesDaoProvider = Provider<ReceivablesDao>((ref) {final db=ref.watch(localDatabaseProvider);return ReceivablesDao(db);});
final activeReceivablesStreamProvider = StreamProvider<List<ReceivableWithCustomer>>((ref){final dao=ref.watch(receivablesDaoProvider);return dao.watchActiveReceivables();});
final receivableSearchQueryProvider = StateProvider<String>((ref)=>'');
final filteredReceivablesStreamProvider = StreamProvider<List<ReceivableWithCustomer>>((ref){final dao=ref.watch(receivablesDaoProvider);final query=ref.watch(receivableSearchQueryProvider);return dao.searchReceivables(query);});
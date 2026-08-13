import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_database.dart';
import '../tables/transaction_table.dart';
import '../tables/finance_table.dart';
import '../tables/product_table.dart';
import '../tables/category_table.dart';
import '../tables/purchase_table.dart';
import '../tables/closing_book_table.dart';

part 'report_dao.g.dart';

class LaporanLabaRugiData {
  final double totalOmset;
  final double totalHpp;
  final double labaKotor;
  final double totalPengeluaran;
  final double labaBersih;
  final int totalTransaksiCount;
  LaporanLabaRugiData({required this.totalOmset, required this.totalHpp, required this.labaKotor, required this.totalPengeluaran, required this.labaBersih, required this.totalTransaksiCount});
}

class TopProductReportData {
  final String productId;
  final String productName;
  final String unitName;
  final double totalQuantity;
  final double totalOmset;
  final double totalProfit;
  TopProductReportData({required this.productId, required this.productName, required this.unitName, required this.totalQuantity, required this.totalOmset, required this.totalProfit});
}

class DailyOmsetReportData {
  final DateTime date;
  final double totalOmset;
  final double totalProfit;
  final int transactionCount;
  DailyOmsetReportData({required this.date, required this.totalOmset, required this.totalProfit, required this.transactionCount});
}

@DriftAccessor(tables: [Transactions, TransactionItems, Expenses, Products, Categories, Payables, Receivables, Purchases, ClosingBooks, CategoryReportSnapshots])
class ReportDao extends DatabaseAccessor<LocalDatabase> with _$ReportDaoMixin {
  ReportDao(LocalDatabase db) : super(db);

  Future<LaporanLabaRugiData> getLaporanLabaRugi(DateTime startDate, DateTime endDate) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0,0,0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23,59,59);
    final rows = await (select(transactionItems).join([innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId))])..where(transactions.date.isBetweenValues(start, end) & transactions.status.isNotIn(['CANCELLED','VOID','Batal','void']))).get();
    double omset=0, totalHpp=0;
    final Set<String> ids={};
    for(final row in rows){
      final item=row.readTable(transactionItems);
      omset+=item.subtotal;
      totalHpp+=item.buyPriceAtTransaction * item.quantity * item.conversionFactor;
      ids.add(item.transactionId);
    }
    final labaKotor=omset-totalHpp;
    final expenseSum=expenses.amount.sum();
    final expRow=await (selectOnly(expenses)..addColumns([expenseSum])..where(expenses.date.isBetweenValues(start, end))).getSingle();
    final totalExpenses=expRow.read(expenseSum)??0.0;
    return LaporanLabaRugiData(totalOmset:omset, totalHpp:totalHpp, labaKotor:labaKotor, totalPengeluaran:totalExpenses, labaBersih:labaKotor-totalExpenses, totalTransaksiCount:ids.length);
  }

  Stream<LaporanLabaRugiData> watchLaporanLabaRugi(DateTime startDate, DateTime endDate) => Stream.fromFuture(getLaporanLabaRugi(startDate, endDate));

  Future<List<TopProductReportData>> getTopSellingProducts({required DateTime startDate, required DateTime endDate, int limit=10}) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0,0,0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23,59,59);
    final rows = await (select(transactionItems).join([innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId)), innerJoin(products, products.id.equalsExp(transactionItems.productId))])..where(transactions.date.isBetweenValues(start, end) & transactions.status.isNotIn(['CANCELLED','VOID','Batal','void']))).get();
    final Map<String, TopProductReportData> grouped={};
    for(final row in rows){
      final item=row.readTable(transactionItems);
      final product=row.readTable(products);
      final qty=item.quantity*item.conversionFactor;
      final omset=item.subtotal;
      final hpp=item.buyPriceAtTransaction*qty;
      final profit=omset-hpp;
      if(grouped.containsKey(item.productId)){
        final ex=grouped[item.productId]!;
        grouped[item.productId]=TopProductReportData(productId:item.productId, productName:product.name, unitName:product.unit, totalQuantity:ex.totalQuantity+qty, totalOmset:ex.totalOmset+omset, totalProfit:ex.totalProfit+profit);
      } else {
        grouped[item.productId]=TopProductReportData(productId:item.productId, productName:product.name, unitName:product.unit, totalQuantity:qty, totalOmset:omset, totalProfit:profit);
      }
    }
    final list=grouped.values.toList()..sort((a,b)=> b.totalQuantity.compareTo(a.totalQuantity));
    return list.take(limit).toList();
  }

  Future<List<DailyOmsetReportData>> getDailyOmsetSummary({required DateTime startDate, required DateTime endDate}) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0,0,0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23,59,59);
    final validTransactions=await (select(transactions)..where((tbl)=> tbl.date.isBetweenValues(start, end) & tbl.status.isNotIn(['CANCELLED','VOID','Batal','void']))..orderBy([(tbl)=> OrderingTerm.asc(tbl.date)])).get();
    final items=await (select(transactionItems).join([innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId))])..where(transactions.date.isBetweenValues(start, end))).get();
    final Map<String,double> profitByTx={};
    for(var r in items){ final it=r.readTable(transactionItems); final profit=it.subtotal-(it.buyPriceAtTransaction*it.quantity*it.conversionFactor); profitByTx[it.transactionId]=(profitByTx[it.transactionId]??0)+profit; }
    final Map<String,DailyOmsetReportData> dailyMap={};
    for(final tx in validTransactions){
      final dateKey="${tx.date.year}-${tx.date.month.toString().padLeft(2,'0')}-${tx.date.day.toString().padLeft(2,'0')}";
      final txDate=DateTime(tx.date.year, tx.date.month, tx.date.day);
      final omset=tx.grandTotal;
      final profit=profitByTx[tx.id]??0;
      if(dailyMap.containsKey(dateKey)){
        final ex=dailyMap[dateKey]!;
        dailyMap[dateKey]=DailyOmsetReportData(date:txDate, totalOmset:ex.totalOmset+omset, totalProfit:ex.totalProfit+profit, transactionCount:ex.transactionCount+1);
      } else {
        dailyMap[dateKey]=DailyOmsetReportData(date:txDate, totalOmset:omset, totalProfit:profit, transactionCount:1);
      }
    }
    return dailyMap.values.toList();
  }

  Future<Map<String,dynamic>> getRealTimeReport({DateTime? start, DateTime? end}) async {
    final startDate=start??DateTime(2022,1,1);
    final endDate=end??DateTime.now();
    final trans=await (select(transactions)..where((t)=> t.date.isBetweenValues(startDate, endDate))).get();
    final transIds=trans.map((e)=> e.id).toList();
    final items=transIds.isEmpty? <TransactionItemData>[] : await (select(transactionItems)..where((t)=> t.transactionId.isIn(transIds))).get();
    final allProducts=await select(products).get();
    final allCategories=await select(categories).get();
    final allPayables=await (select(payables)..where((t)=> t.createdAt.isBetweenValues(startDate, endDate))).get();
    final allReceivables=await (select(receivables)..where((t)=> t.createdAt.isBetweenValues(startDate, endDate))).get();
    final allPurchases=await (select(purchases)..where((t)=> t.date.isBetweenValues(startDate, endDate))).get();
    final allExpenses=await (select(expenses)..where((t)=> t.date.isBetweenValues(startDate, endDate))).get();
    final omset=trans.fold<double>(0,(p,e)=> p+e.grandTotal);
    final hpp=items.fold<double>(0,(p,e)=> p+(e.buyPriceAtTransaction*e.quantity*e.conversionFactor));
    final totalBeli=allPurchases.fold<double>(0,(p,e)=> p+e.totalAmount);
    final biaya=allExpenses.fold<double>(0,(p,e)=> p+e.amount);
    final labaKotor=omset-hpp;
    final labaBersih=labaKotor-biaya;
    final Map<String,Map<String,dynamic>> categoryMap={};
    for(final cat in allCategories){
      final catProducts=allProducts.where((p)=> p.categoryId==cat.id).toList();
      final catProductIds=catProducts.map((e)=> e.id).toSet();
      final catItems=items.where((i)=> catProductIds.contains(i.productId)).toList();
      final catOmset=catItems.fold<double>(0,(p,e)=> p+e.subtotal);
      final catHpp=catItems.fold<double>(0,(p,e)=> p+(e.buyPriceAtTransaction*e.quantity*e.conversionFactor));
      final catStockVal=catProducts.fold<double>(0,(p,e)=> p+(e.stock*e.buyPrice));
      categoryMap[cat.id]={'name':cat.name,'color':cat.colorHex,'omset':catOmset,'hpp':catHpp,'laba':catOmset-catHpp,'qty':catItems.fold<double>(0,(p,e)=> p+e.quantity),'stockVal':catStockVal,'skuCount':catProducts.length};
    }
    return {'omset':omset,'hpp':hpp,'totalBeli':totalBeli,'biaya':biaya,'labaKotor':labaKotor,'labaBersih':labaBersih,'stockAkhir':allProducts.fold<double>(0,(p,e)=> p+(e.stock*e.buyPrice)),'piutang':allReceivables.fold<double>(0,(p,e)=> p+e.remainingAmount),'hutang':allPayables.fold<double>(0,(p,e)=> p+e.remainingAmount),'transCount':trans.length,'categoryMap':categoryMap,'topCategory':categoryMap.entries.isEmpty?null:categoryMap.entries.reduce((a,b)=> (a.value['laba'] as double)>(b.value['laba'] as double)?a:b),'worstCategory':categoryMap.entries.isEmpty?null:categoryMap.entries.reduce((a,b)=> (a.value['laba'] as double)<(b.value['laba'] as double)?a:b)};
  }

  Future<void> lockClosingBook(ClosingBooksCompanion data) async => await into(closingBooks).insert(data);
  Future<List<ClosingBookData>> getAllClosingBooks() => (select(closingBooks)..orderBy([(t)=> OrderingTerm.desc(t.createdAt)])).get();
}

final reportDaoProvider = Provider<ReportDao>((ref) { final db=ref.watch(localDatabaseProvider); return ReportDao(db); });
final monthlyLabaRugiProvider = StreamProvider<LaporanLabaRugiData>((ref) {
  final dao=ref.watch(reportDaoProvider);
  final now=DateTime.now();
  return dao.watchLaporanLabaRugi(DateTime(now.year, now.month, 1), DateTime(now.year, now.month+1,0));
});
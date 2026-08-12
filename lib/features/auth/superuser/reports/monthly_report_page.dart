import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:intl/intl.dart';

class MonthlyFilter {
  DateTime month;
  String search;
  String status;
  String sortBy;
  MonthlyFilter({DateTime? month, this.search = '', this.status = 'SEMUA', this.sortBy = 'TANGGAL_DESC'}) : month = month ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
  MonthlyFilter copyWith({DateTime? month, String? search, String? status, String? sortBy}) {
    return MonthlyFilter(month: month ?? this.month, search: search ?? this.search, status: status ?? this.status, sortBy: sortBy ?? this.sortBy);
  }
}

final monthlyFilterProvider = StateProvider<MonthlyFilter>((ref) => MonthlyFilter());

final monthlyReportProvider = FutureProvider<MonthlyReport>((ref) async {
  final db = ref.watch(localDatabaseProvider);
  final filter = ref.watch(monthlyFilterProvider);
  return MonthlyReport.generate(db, filter);
});

class MonthlyReport {
  final List<PayableData> hutangList;
  final List<ReceivableData> piutangList;
  final List<ProductData> stockList;
  final double totalHutang;
  final double totalPiutang;
  final double totalStockValue;
  final int totalSKU;

  MonthlyReport({required this.hutangList, required this.piutangList, required this.stockList, required this.totalHutang, required this.totalPiutang, required this.totalStockValue, required this.totalSKU});

  static Future<MonthlyReport> generate(LocalDatabase db, MonthlyFilter f) async {
    final start = DateTime(f.month.year, f.month.month, 1);
    final end = DateTime(f.month.year, f.month.month + 1, 0, 23, 59, 59);
    var hutangAll = await db.payablesDao.getByDateRange(start, end);
    var piutangAll = await db.receivablesDao.getByDateRange(start, end);
    var stockAll = await db.productDao.getAllProducts();

    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      hutangAll = hutangAll.where((e) => (e.supplierName ?? '').toLowerCase().contains(q)).toList();
      piutangAll = piutangAll.where((e) => (e.customerName ?? '').toLowerCase().contains(q)).toList();
      stockAll = stockAll.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    if (f.status == 'BELUM') {
      hutangAll = hutangAll.where((e) => e.remainingAmount > 0).toList();
      piutangAll = piutangAll.where((e) => e.remainingAmount > 0).toList();
    }

    final totalHutang = hutangAll.fold<double>(0, (p, e) => p + e.remainingAmount);
    final totalPiutang = piutangAll.fold<double>(0, (p, e) => p + e.remainingAmount);
    final totalStock = stockAll.fold<double>(0, (p, e) => p + (e.stock * e.hargaBeli));

    return MonthlyReport(hutangList: hutangAll, piutangList: piutangAll, stockList: stockAll, totalHutang: totalHutang, totalPiutang: totalPiutang, totalStockValue: totalStock, totalSKU: stockAll.length);
  }
}

class MonthlyReportPage extends ConsumerStatefulWidget {
  const MonthlyReportPage({super.key});
  @override
  ConsumerState<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends ConsumerState<MonthlyReportPage> with SingleTickerProviderStateMixin {
  late TabController tabController;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(monthlyFilterProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Bulanan'),
        backgroundColor: Colors.indigo.shade700,
        bottom: TabBar(controller: tabController, tabs: const [Tab(text: 'HUTANG'), Tab(text: 'PIUTANG'), Tab(text: 'STOCK')]),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime.now(), initialDate: filter.month);
                          if (picked != null) {
                            ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(month: DateTime(picked.year, picked.month, 1));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigo)),
                          child: Text(DateFormat('MMMM yyyy', 'id_ID').format(filter.month), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: filter.status,
                      items: const [
                        DropdownMenuItem(value: 'SEMUA', child: Text('Semua')),
                        DropdownMenuItem(value: 'BELUM', child: Text('Belum')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(status: v);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(hintText: 'Cari supplier customer SKU', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
                  onChanged: (v) {
                    ref.read(monthlyFilterProvider.notifier).state = filter.copyWith(search: v);
                  },
                ),
              ],
            ),
          ),
          reportAsync.when(
            data: (r) => Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  sumCard('Hutang', fmt.format(r.totalHutang), Colors.red),
                  const SizedBox(width: 6),
                  sumCard('Piutang', fmt.format(r.totalPiutang), Colors.orange),
                  const SizedBox(width: 6),
                  sumCard('Stock', fmt.format(r.totalStockValue), Colors.blue),
                ],
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Error $e'),
          ),
          Expanded(
            child: reportAsync.when(
              data: (r) => TabBarView(
                controller: tabController,
                children: [
                  ListView.builder(itemCount: r.hutangList.length, itemBuilder: (_, i) {
                    final h = r.hutangList[i];
                    return Card(child: ListTile(title: Text('${h.invoiceNo}'), subtitle: Text('${h.supplierName}'), trailing: Text(fmt.format(h.remainingAmount))));
                  }),
                  ListView.builder(itemCount: r.piutangList.length, itemBuilder: (_, i) {
                    final p = r.piutangList[i];
                    return Card(child: ListTile(title: Text('${p.invoiceNo}'), subtitle: Text('${p.customerName}'), trailing: Text(fmt.format(p.remainingAmount))));
                  }),
                  ListView.builder(itemCount: r.stockList.length, itemBuilder: (_, i) {
                    final s = r.stockList[i];
                    return Card(child: ListTile(title: Text(s.name), subtitle: Text('Stok ${s.stock}'), trailing: Text(fmt.format(s.stock * s.hargaBeli))));
                  }),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget sumCard(String title, String nominal, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)), Text(nominal, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}
// lib/features/finance/finance_report_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/utils/format_rupiah.dart';
import 'finance_service.dart';

class FinanceReportPage extends ConsumerStatefulWidget {
  const FinanceReportPage({super.key});

  @override
  ConsumerState<FinanceReportPage> createState() => _FinanceReportPageState();
}

class _FinanceReportPageState extends ConsumerState<FinanceReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final labaRugiAsync = ref.watch(labaRugiProvider(_selectedRange));
    final neracaAsync = ref.watch(neracaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan UD. Putra Surabaya'),
        backgroundColor: const Color(0xFF007F00),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Laba Rugi'),
            Tab(icon: Icon(Icons.account_balance), text: 'Neraca Keuangan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: LABA RUGI
          labaRugiAsync.when(
            data: (data) => _buildLabaRugiView(data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Gagal memuat data: $err')),
          ),

          // TAB 2: NERACA
          neracaAsync.when(
            data: (data) => _buildNeracaView(data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Gagal memuat data: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildLabaRugiView(LabaRugiModel data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LAPORAN LABA RUGI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF007F00))),
                  const Divider(),
                  _rowItem('Penjualan Kotor', formatRupiah(data.totalPenjualanKotor)),
                  _rowItem('Diskon Penjualan', '(${formatRupiah(data.totalDiskonPenjualan)})', isRed: true),
                  const Divider(),
                  _rowItem('Penjualan Bersih', formatRupiah(data.totalPenjualanBersih), isBold: true),
                  _rowItem('Harga Pokok Penjualan (HPP)', '(${formatRupiah(data.totalHPP)})', isRed: true),
                  const Divider(),
                  _rowItem('LABA KOTOR', formatRupiah(data.labaKotor), isBold: true, color: Colors.blue.shade900),
                  const SizedBox(height: 12),
                  _rowItem('Beban Operasional & Usaha', '(${formatRupiah(data.totalBebanOperasional)})', isRed: true),
                  const Divider(thickness: 2),
                  _rowItem(
                    'LABA BERSIH OPERASIONAL',
                    formatRupiah(data.labaBersih),
                    isBold: true,
                    color: data.labaBersih >= 0 ? const Color(0xFF00A65A) : Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeracaView(NeracaModel data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('LAPORAN NERACA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF007F00))),
                      Chip(
                        label: Text(data.isBalanced ? 'BALANCED' : 'UNBALANCED', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        backgroundColor: data.isBalanced ? Colors.green : Colors.red,
                      )
                    ],
                  ),
                  const Divider(),
                  const Text('AKTIVA (ASSETS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  _rowItem('Kas & Bank', formatRupiah(data.kasDanBank)),
                  _rowItem('Piutang Usaha (AR)', formatRupiah(data.piutangUsaha)),
                  _rowItem('Persediaan Barang Dagangan', formatRupiah(data.nilaiPersediaanBarang)),
                  const Divider(),
                  _rowItem('TOTAL AKTIVA', formatRupiah(data.totalAktiva), isBold: true, color: Colors.blue.shade900),
                  const SizedBox(height: 20),
                  const Text('PASIVA (KEWAJIBAN & EKUITAS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  _rowItem('Hutang Usaha / Supplier (AP)', formatRupiah(data.hutangUsaha)),
                  _rowItem('Modal & Laba Ditahan', formatRupiah(data.modalDanLabaDitahan)),
                  const Divider(),
                  _rowItem('TOTAL PASIVA', formatRupiah(data.totalPasiva), isBold: true, color: Colors.orange.shade900),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowItem(String title, String value, {bool isBold = false, bool isRed = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: isRed ? Colors.red : (color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

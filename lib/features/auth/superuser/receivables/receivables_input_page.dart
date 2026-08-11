import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'invoice_generator.dart';

// === PROVIDER FIX - TARUH DI ATAS ===
final allCustomersStreamProvider = StreamProvider<List<CustomerData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.customerDao.watchAllCustomers();
});
// salesmenStreamProvider sudah ada di user_dao.dart, jangan bikin lagi di sini
// kita pakai yang dari user_dao

class ReceivablesInputPage extends ConsumerStatefulWidget {
  const ReceivablesInputPage({super.key});
  @override ConsumerState<ReceivablesInputPage> createState() => _ReceivablesInputPageState();
}

class _ReceivablesInputPageState extends ConsumerState<ReceivablesInputPage> {
  final _formKey = GlobalKey<FormState>();
  CustomerData? _selectedCustomer;
  UserData? _selectedSales;
  String _kenapaNgendap = 'MACET';
  final _totalCtrl = TextEditingController();
  final _dpCtrl = TextEditingController(text: '0');
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  DateTime _invoiceDate = DateTime.now();
  String _autoInvoice = 'Pilih Customer dulu';

  void _updateInvoice() {
    if (_selectedCustomer != null) {
      setState(() {
        _autoInvoice = InvoiceGenerator.generateReceivableNo(
          customerId: _selectedCustomer!.id, 
          customerName: _selectedCustomer!.name
        );
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate() || _selectedCustomer == null) return;
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    final dp = double.tryParse(_dpCtrl.text) ?? 0;
    if (total <=0) return;

    final db = ref.read(localDatabaseProvider);
    await db.receivablesDao.catatPiutangBaru(
      transactionId: _autoInvoice,
      customerId: _selectedCustomer!.id,
      totalAmount: total,
      dpAmount: dp,
      dueDate: _dueDate,
      salesId: _selectedSales?.id,
      kenapaNgendap: _kenapaNgendap,
      invoiceDate: _invoiceDate,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Piutang $_autoInvoice disimpan')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersStreamProvider);
    final salesAsync = ref.watch(salesmenStreamProvider); // dari user_dao.dart

    return Scaffold(
      appBar: AppBar(title: const Text('Input Piutang Baru - Anti Ngendown')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AUTO NOMOR INVOICE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(_autoInvoice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  Text('INV-DDMMYY-IDCSTMR-NAMACSTMR-JAM-RAND', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            customersAsync.when(
              data: (list) => DropdownButtonFormField<CustomerData>(
                value: _selectedCustomer,
                decoration: const InputDecoration(labelText: 'Customer *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                items: list.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} - Sisa: ${c.sisaHutang}'))).toList(),
                onChanged: (v){ setState(()=>_selectedCustomer=v); _updateInvoice(); },
                validator: (v)=> v==null ? 'Wajib pilih customer' : null,
              ),
              loading: ()=> const CircularProgressIndicator(),
              error: (e,s)=> Text('Error $e'),
            ),
            const SizedBox(height: 12),
            salesAsync.when(
              data: (list) => DropdownButtonFormField<UserData>(
                value: _selectedSales,
                decoration: const InputDecoration(labelText: 'Salesman Biang Ngendown', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                items: list.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v)=> setState(()=>_selectedSales=v),
              ),
              loading: ()=> const SizedBox(),
              error: (_,__)=> const SizedBox(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _kenapaNgendap,
              decoration: const InputDecoration(labelText: 'Kenapa Ngendap *', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'MACET', child: Text('MACET - Susah Bayar')),
                DropdownMenuItem(value: 'KONSINYASI', child: Text('KONSINYASI - Titip Jual')),
                DropdownMenuItem(value: 'TITIP', child: Text('TITIP - Barang di Customer')),
                DropdownMenuItem(value: 'BS', child: Text('BS - Barang Sortir')),
                DropdownMenuItem(value: 'RETUR', child: Text('RETUR - Belum Diproses')),
                DropdownMenuItem(value: 'TEMPO', child: Text('TEMPO - Normal')),
              ],
              onChanged: (v)=> setState(()=>_kenapaNgendap=v!),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _totalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Piutang *', border: OutlineInputBorder(), prefixText: 'Rp '), validator: (v)=> (v==null||v.isEmpty)?'Wajib isi':null),
            const SizedBox(height: 12),
            TextFormField(controller: _dpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'DP / Dibayar', border: OutlineInputBorder(), prefixText: 'Rp ')),
            const SizedBox(height: 12),
            ListTile(
              title: Text('Jatuh Tempo: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: _dueDate); if(d!=null) setState(()=>_dueDate=d); },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _simpan, icon: const Icon(Icons.save), label: const Text('SIMPAN PIUTANG + CCTV'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50))),
          ],
        ),
      ),
    );
  }
}
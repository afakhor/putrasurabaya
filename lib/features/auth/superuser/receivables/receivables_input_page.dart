import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'invoice_generator.dart';

// Provider lokal - tidak perlu import user_dao.dart lagi
final allCustomersStreamProvider = StreamProvider<List<CustomerData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.customerDao.watchAllCustomers();
});

final salesmenStreamProviderLocal = StreamProvider<List<UserData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return db.userDao.watchAllSalesmen();
});

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
  String _autoInvoice = 'Pilih Customer dulu';

  void _updateInvoice() {
    if (_selectedCustomer != null) {
      setState(() {
        _autoInvoice = InvoiceGenerator.generateReceivableNo(customerId: _selectedCustomer!.id, customerName: _selectedCustomer!.name);
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate() || _selectedCustomer == null) return;
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    final db = ref.read(localDatabaseProvider);
    await db.receivablesDao.catatPiutangBaru(transactionId: _autoInvoice, customerId: _selectedCustomer!.id, totalAmount: total, dpAmount: double.tryParse(_dpCtrl.text)??0, dueDate: _dueDate, salesId: _selectedSales?.id, kenapaNgendap: _kenapaNgendap, invoiceDate: DateTime.now());
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Piutang $_autoInvoice disimpan'))); Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersStreamProvider);
    final salesAsync = ref.watch(salesmenStreamProviderLocal);

    return Scaffold(
      appBar: AppBar(title: const Text('Input Piutang Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue)), child: Text(_autoInvoice, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
            const SizedBox(height: 12),
            customersAsync.when(data: (list) => DropdownButtonFormField<CustomerData>(value: _selectedCustomer, decoration: const InputDecoration(labelText: 'Customer *', border: OutlineInputBorder()), items: list.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(), onChanged: (v){ setState(()=>_selectedCustomer=v); _updateInvoice(); }, validator: (v)=> v==null? 'Wajib' : null), loading: ()=> const CircularProgressIndicator(), error: (e,s)=> Text('$e')),
            const SizedBox(height: 12),
            salesAsync.when(data: (list) => DropdownButtonFormField<UserData>(value: _selectedSales, decoration: const InputDecoration(labelText: 'Salesman', border: OutlineInputBorder()), items: list.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: (v)=> setState(()=>_selectedSales=v)), loading: ()=> const SizedBox(), error: (_,__)=> const SizedBox()),
            const SizedBox(height: 12),
            TextFormField(controller: _totalCtrl, decoration: const InputDecoration(labelText: 'Total *', border: OutlineInputBorder()), validator: (v)=> v!.isEmpty? 'Wajib' : null),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _simpan, child: const Text('SIMPAN')),
          ],
        ),
      ),
    );
  }
}
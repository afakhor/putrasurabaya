import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/payables_dao.dart';

class PayableDetailPage extends ConsumerStatefulWidget {
  final PayableData payable;
  const PayableDetailPage({super.key, required this.payable});
  @override ConsumerState<PayableDetailPage> createState()=> _PayableDetailPageState();
}

class _PayableDetailPageState extends ConsumerState<PayableDetailPage> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final dao = ref.watch(payablesDaoProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text('Detail ${widget.payable.purchaseId?? widget.payable.id}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(child: ListTile(title: Text('Supplier: ${widget.payable.supplierName}'), subtitle: Text('Invoice: ${widget.payable.purchaseId}\nJatuh Tempo: ${widget.payable.dueDate}\nStatus: ${widget.payable.payableStatus.name}\nDays Overdue: ${widget.payable.daysOverdue}\nTotal: ${fmt.format(widget.payable.totalAmount)}\nSisa: ${fmt.format(widget.payable.remainingAmount)}'))),
          const SizedBox(height: 12),
          const Text('Mutasi Stok Terkait (Rule Emas: 1 Faktur = 1 Mutasi)', style: TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder(
            future: (db.select(db.stockMutations)..where((t)=> t.referenceNo.equals(widget.payable.purchaseId??'') | t.referenceId.equals(widget.payable.purchaseId??'') | t.referenceNo.equals(widget.payable.id) | t.referenceId.equals(widget.payable.id))).get(),
            builder: (c, snap){
              if(!snap.hasData) return const CircularProgressIndicator();
              final list = snap.data as List<StockMutationData>;
              if(list.isEmpty) return const Card(child: ListTile(title: Text('⚠️ HUTANG FIKTIF - tidak ada mutasi pembelian!', style: TextStyle(color: Colors.red))));
              return Column(children: list.map((m)=> Card(child: ListTile(dense:true, title: Text('${m.type} ${m.productId} qty ${m.quantity}'), subtitle: Text('Before ${m.stockBefore} After ${m.stockAfter} Ref ${m.referenceNo}')))).toList());
            },
          ),
          const SizedBox(height: 12),
          const Text('History Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          StreamBuilder(
            stream: dao.watchPaymentHistory(widget.payable.id),
            builder: (c, snap){
              if(!snap.hasData) return const SizedBox();
              final hist = snap.data!;
              return Column(children: hist.map((h)=> ListTile(dense:true, title: Text('${fmt.format(h.amount)} - ${h.paymentMethod}'), subtitle: Text('${h.paymentDate} ${h.notes??''}'))).toList());
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text('Bayar Hutang Ini (Wajib InvoiceNo)'),
            onPressed: ()=> _bayarDialog(),
          ),
        ],
      ),
    );
  }

  void _bayarDialog(){
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (c)=> AlertDialog(
      title: Text('Bayar ${widget.payable.purchaseId}'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal')),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(c), child: const Text('Batal')),
        ElevatedButton(onPressed: () async {
          final nom = double.tryParse(ctrl.text)??0;
          if(nom<=0) return;
          // RULE EMAS: bayar harus pakai invoiceNo spesifik
          await ref.read(localDatabaseProvider).onPayablePaid(invoiceNo: widget.payable.purchaseId??widget.payable.id, amount: nom, userId: 'owner-01');
          if(mounted) Navigator.pop(c);
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil via invoiceNo')));
        }, child: const Text('Bayar')),
      ],
    ));
  }
}
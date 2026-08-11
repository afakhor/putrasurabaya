import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/payables_dao.dart';

class PayableDetailPage extends ConsumerStatefulWidget {
  final PayableData payable;
  const PayableDetailPage({super.key, required this.payable});

  @override
  ConsumerState<PayableDetailPage> createState() => _PayableDetailPageState();
}

class _PayableDetailPageState extends ConsumerState<PayableDetailPage> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final dao = ref.watch(payablesDaoProvider);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final invNo = widget.payable.purchaseId ?? widget.payable.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail $invNo', style: const TextStyle(fontSize: 14)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice: ${widget.payable.purchaseId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Supplier: ${widget.payable.supplierName ?? "-"}'),
                  Text('Jatuh Tempo: ${widget.payable.dueDate != null ? DateFormat('dd MMM yyyy').format(widget.payable.dueDate!) : "-"}'),
                  Text('Status: ${widget.payable.payableStatus.name} | Overdue: ${widget.payable.daysOverdue} hari'),
                  const Divider(),
                  Text('Total: ${fmt.format(widget.payable.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Sisa: ${fmt.format(widget.payable.remainingAmount)}', style: TextStyle(fontWeight: FontWeight.bold, color: widget.payable.remainingAmount > 0 ? Colors.red : Colors.green)),
                  Text('Bayar: ${fmt.format(widget.payable.paidAmount)}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Text('Mutasi Stok Terkait (1 Faktur = 1 Mutasi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),

          // === FIX: GANTI OPERATOR | JADI FILTER DART ===
          FutureBuilder<List<StockMutationData>>(
            future: () async {
              final id = widget.payable.id;
              final purchaseId = widget.payable.purchaseId ?? '';
              // ambil semua lalu filter di Dart (anti error Expression<bool> | )
              final allMutasi = await db.select(db.stockMutations).get();
              return allMutasi.where((m) {
                return m.referenceNo == purchaseId ||
                       m.referenceId == purchaseId ||
                       m.referenceNo == id ||
                       m.referenceId == id ||
                       m.referenceNo == widget.payable.purchaseId ||
                       m.referenceId == widget.payable.purchaseId;
              }).toList();
            }(),
            builder: (c, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              if (list.isEmpty) {
                return const Card(
                  color: Color(0xFFFFEBEE),
                  child: ListTile(
                    leading: Icon(Icons.warning, color: Colors.red),
                    title: Text('⚠️ HUTANG FIKTIF - tidak ada mutasi pembelian!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Text('Payable tanpa StockMutations - masuk FraudAlerts MERAH + AuditLogs', style: TextStyle(fontSize: 10)),
                  ),
                );
              }
              return Column(
                children: list.map((m) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    title: Text('${m.type} ${m.productId} qty ${m.quantity}', style: const TextStyle(fontSize: 12)),
                    subtitle: Text('Before ${m.stockBefore} -> After ${m.stockAfter} Ref ${m.referenceNo} Date ${m.mutationDate}', style: const TextStyle(fontSize: 10)),
                  ),
                )).toList(),
              );
            },
          ),

          const SizedBox(height: 16),
          const Text('History Pembayaran (Analytics CCTV)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),

          StreamBuilder<List<DebtPaymentData>>(
            stream: dao.watchPaymentHistory(widget.payable.id),
            builder: (c, snap) {
              if (!snap.hasData || snap.data!.isEmpty) return const Text('Belum ada pembayaran', style: TextStyle(fontSize: 11));
              final hist = snap.data!;
              return Column(
                children: hist.map((h) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.payment, size: 16),
                  title: Text('${fmt.format(h.amount)} - ${h.paymentMethod}', style: const TextStyle(fontSize: 12)),
                  subtitle: Text('${DateFormat('dd MMM HH:mm').format(h.paymentDate)} ${h.notes ?? ""}', style: const TextStyle(fontSize: 10)),
                )).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text('Bayar Hutang Ini (Wajib InvoiceNo)', style: TextStyle(color: Colors.white)),
              onPressed: () => _bayarDialog(invNo),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _bayarDialog(String invNo) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Bayar $invNo'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final nom = double.tryParse(ctrl.text) ?? 0;
              if (nom <= 0) return;
              // RULE EMAS: harus pakai invoiceNo spesifik + otomatis masuk auditLogs
              await ref.read(localDatabaseProvider).onPayablePaid(invoiceNo: invNo, amount: nom, userId: 'owner-01');
              if (mounted) Navigator.pop(c);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pembayaran $invNo Rp $nom berhasil + masuk CCTV Analytics')));
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }
}
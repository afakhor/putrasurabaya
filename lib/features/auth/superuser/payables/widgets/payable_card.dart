import 'package:flutter/material.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/payables_dao.dart';
import 'package:intl/intl.dart';

class PayableCard extends StatelessWidget {
  final PayableData payable;
  final String supplierName;
  final bool isFiktif;
  final VoidCallback? onTap;
  const PayableCard({super.key, required this.payable, required this.supplierName, this.isFiktif = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = payable.payableStatus;
    Color badgeColor;
    String label;
    switch(status){
      case PayableStatus.overdue: badgeColor = Colors.red; label = 'OVERDUE ${payable.daysOverdue}h'; break;
      case PayableStatus.dueSoon: badgeColor = Colors.orange; label = 'JATUH TEMPO ${payable.daysOverdue.abs()}h lagi'; break;
      case PayableStatus.belumJatuhTempo: badgeColor = Colors.grey; label = 'BELUM JATUH TEMPO'; break;
      case PayableStatus.lunas: badgeColor = Colors.green; label = 'LUNAS'; break;
    }
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final due = payable.dueDate!=null? DateFormat('dd MMM yyyy').format(payable.dueDate!) : '-';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isFiktif? Colors.red[50] : null,
      child: ListTile(
        onTap: onTap,
        title: Row(children: [
          Expanded(child: Text('${payable.purchaseId?? payable.id} • $supplierName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9))),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text('Jatuh Tempo: $due | Sisa: ${fmt.format(payable.remainingAmount)} / Total: ${fmt.format(payable.totalAmount)}', style: const TextStyle(fontSize: 10)),
          if(isFiktif) const Text('⚠️ HUTANG FIKTIF: tanpa mutasi pembelian!', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
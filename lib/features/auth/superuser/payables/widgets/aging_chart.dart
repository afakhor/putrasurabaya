import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgingChart extends StatelessWidget {
  final Map<String, dynamic> summary;
  const AgingChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final a0 = summary['aging_0_30'] as double??? 0;
    final a31 = summary['aging_31_60'] as double??? 0;
    final a60 = summary['aging_60plus'] as double??? 0;
    final total = (a0+a31+a60)==0?1:(a0+a31+a60);

    Widget bar(String label, double val, Color c){
      final pct = val/total;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 11)), Text(fmt.format(val), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: pct, color: c, minHeight: 8, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 8),
      ]);
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Aging Hutang (Keterlambatan)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        bar('0-30 Hari', a0, Colors.orange),
        bar('31-60 Hari', a31, Colors.deepOrange),
        bar('60+ Hari', a60, Colors.red),
      ])),
    );
  }
}
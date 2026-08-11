import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/daos/payables_dao.dart';
import 'widgets/payable_card.dart';
import 'payable_detail_page.dart';
import 'widgets/payable_alert_banner.dart';

class PayablesListPage extends ConsumerStatefulWidget {
  const PayablesListPage({super.key});
  @override ConsumerState<PayablesListPage> createState()=> _PayablesListPageState();
}

class _PayablesListPageState extends ConsumerState<PayablesListPage> {
  String filter = 'all'; // all, overdue, dueSoon, belumJatuhTempo, lunas
  String keyword = '';

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(payablesDaoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hutang Supplier - Anti Bocor'), bottom: PreferredSize(preferredSize: const Size.fromHeight(100), child: Column(children: [
        const PayableAlertBanner(),
        Padding(padding: const EdgeInsets.all(8), child: TextField(onChanged: (v)=> setState(()=> keyword=v.toLowerCase()), decoration: const InputDecoration(hintText: 'Cari invoiceNo / supplier', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), isDense: true))),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _chip('Semua','all'), _chip('Overdue','overdue'), _chip('Due Soon 3 Hari','dueSoon'), _chip('Belum Jatuh Tempo','belumJatuhTempo'),
        ])),
      ]))),
      body: StreamBuilder<List<PayableData>>(
        stream: dao.watchActivePayables(),
        builder: (c, snap){
          if(!snap.hasData) return const Center(child: CircularProgressIndicator());
          var list = snap.data!;
          // filter keyword
          if(keyword.isNotEmpty){ list = list.where((p)=> (p.purchaseId??'').toLowerCase().contains(keyword) || (p.supplierName??'').toLowerCase().contains(keyword) || p.id.toLowerCase().contains(keyword)).toList(); }
          // filter status IPOS
          if(filter!='all'){ list = list.where((p){
            if(filter=='overdue') return p.payableStatus==PayableStatus.overdue;
            if(filter=='dueSoon') return p.payableStatus==PayableStatus.dueSoon;
            if(filter=='belumJatuhTempo') return p.payableStatus==PayableStatus.belumJatuhTempo;
            return true;
          }).toList(); }
          // urgent sort by dueDate
          list = dao.getUrgentPayables(list);

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (c,i){
              final p = list[i];
              return FutureBuilder<bool>(
                future: dao.isPayableFiktif(p),
                builder: (c2, fiktifSnap){
                  final isFiktif = fiktifSnap.data??false;
                  return PayableCard(
                    payable: p,
                    supplierName: p.supplierName?? '-',
                    isFiktif: isFiktif,
                    onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> PayableDetailPage(payable: p))),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _chip(String label, String val){
    final sel = filter==val;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FilterChip(label: Text(label, style: const TextStyle(fontSize: 11)), selected: sel, onSelected: (_)=> setState(()=> filter=val)));
  }
}
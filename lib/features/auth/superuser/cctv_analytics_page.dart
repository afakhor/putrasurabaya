import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/constant/audit_constant.dart';

class CctvAnalyticsPage extends ConsumerStatefulWidget {
  const CctvAnalyticsPage({super.key});
  @override
  ConsumerState<CctvAnalyticsPage> createState() => _CctvAnalyticsPageState();
}

class _CctvAnalyticsPageState extends ConsumerState<CctvAnalyticsPage> {
  String _search = '';
  String _tierFilter = 'SEMUA';
  String _paymentFilter = 'SEMUA';
  String _userFilter = 'SEMUA';
  DateTimeRange? _dateRange;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final auditDao = db.auditLogDao;
    final userDao = db.userDao;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CCTV ANALYTICS - FULL FILTER', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState((){})),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(145),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              Row(children: [
                Expanded(child: TextField(
                  decoration: const InputDecoration(hintText: 'kode / customer / invoice / user', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                  onChanged: (v)=> setState(()=> _search=v),
                )),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(_dateRange==null ? 'Tanggal' : "${DateFormat("dd/MM").format(_dateRange!.start)}-${DateFormat("dd/MM").format(_dateRange!.end)}", style: const TextStyle(fontSize: 10)),
                  onPressed: () async {
                    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now().add(const Duration(days: 1)));
                    if(picked!=null) setState(()=> _dateRange=picked);
                  },
                ),
                if(_dateRange!=null) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: ()=> setState(()=> _dateRange=null)),
              ]),
              const SizedBox(height: 8),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                _chip('SEMUA', _tierFilter, (v)=> setState(()=> _tierFilter=v), Colors.black),
                _chip('TIER 1', AuditAction.jualTier1, (v)=> setState(()=> _tierFilter=v), Colors.green),
                _chip('TIER 2', AuditAction.jualTier2, (v)=> setState(()=> _tierFilter=v), Colors.blue),
                _chip('TIER 3', AuditAction.jualTier3, (v)=> setState(()=> _tierFilter=v), Colors.orange),
                _chip('KULAK', AuditAction.kulakHppMa, (v)=> setState(()=> _tierFilter=v), Colors.purple),
                _chip('RUSAK', AuditAction.keluarRusak, (v)=> setState(()=> _tierFilter=v), Colors.red),
                _chip('OPNAME -', AuditAction.opnameMinus, (v)=> setState(()=> _tierFilter=v), Colors.brown),
                _chip('OPNAME +', AuditAction.opnamePlus, (v)=> setState(()=> _tierFilter=v), Colors.teal),
                _chip('RUGI', AuditAction.jualRugi, (v)=> setState(()=> _tierFilter=v), Colors.redAccent),
              ])),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                    _chip('PAY SEMUA', 'SEMUA', (v)=> setState(()=> _paymentFilter=v), null, true),
                    _chip('LUNAS', 'LUNAS', (v)=> setState(()=> _paymentFilter=v), null, true),
                    _chip('PARTIAL', 'PARTIAL', (v)=> setState(()=> _paymentFilter=v), null, true),
                    _chip('BELUM KIRIM', 'BELUM_KIRIM', (v)=> setState(()=> _paymentFilter=v), null, true),
                    _chip('CASH', 'CASH', (v)=> setState(()=> _paymentFilter=v), null, true),
                  ])),
                ),
                FutureBuilder<List<UserData>>(
                  future: userDao.getAllUsers(),
                  builder: (ctx, snap){
                    final users = snap.data?? [];
                    return DropdownButton<String>(
                      value: _userFilter,
                      isDense: true,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black),
                      items: [
                        const DropdownMenuItem(value: 'SEMUA', child: Text('SEMUA USER')),
                        const DropdownMenuItem(value: 'OWNER', child: Text('OWNER SAJA')),
                        ...users.where((u)=> u.role!='superuser').map((u)=> DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.role})'))),
                      ],
                      onChanged: (v)=> setState(()=> _userFilter=v??'SEMUA'),
                    );
                  },
                ),
              ]),
            ]),
          ),
        ),
      ),
      body: StreamBuilder<List<AuditLogData>>(
        stream: auditDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, actionType: _tierFilter=='SEMUA'? null : _tierFilter, start: _dateRange?.start, end: _dateRange?.end),
        builder: (ctx, snap) {
          if(!snap.hasData) return const Center(child: CircularProgressIndicator());
          var logs = snap.data!;

          if(_userFilter!='SEMUA'){
            if(_userFilter=='OWNER'){
              logs = logs.where((e)=> e.userRole.toLowerCase().contains('owner') || e.userRole.toLowerCase().contains('superuser')).toList();
            } else {
              logs = logs.where((e)=> e.userId==_userFilter).toList();
            }
          }

          if(_paymentFilter!='SEMUA'){
            logs = logs.where((e){
              if(e.newValue==null) return false;
              try{ final nv = jsonDecode(e.newValue!); return (nv['payment']?.toString().contains(_paymentFilter)?? false) || e.description.contains(_paymentFilter); }catch(_){ return e.description.contains(_paymentFilter); }
            }).toList();
          }

          double omsetOwner = 0, labaOwner = 0;
          Map<String, double> omsetPerSales = {}, labaPerSales = {}, omsetPerItem = {};
          final parsed = logs.map((e){
            final oldV = e.oldValue!=null ? jsonDecode(e.oldValue!) as Map : <String,dynamic>{};
            final newV = e.newValue!=null ? jsonDecode(e.newValue!) as Map : <String,dynamic>{};
            final harga = ((newV['harga_jual']??0) as num).toDouble();
            final qty = ((newV['qty']??0) as num).toDouble();
            final hpp = ((newV['hpp_ma']?? oldV['hpp_ma']??0) as num).toDouble();
            final total = harga * qty;
            final laba = (harga - hpp) * qty;
            return {'log': e, 'oldV': oldV, 'newV': newV, 'total': total, 'laba': laba, 'harga': harga, 'qty': qty, 'hpp': hpp};
          }).toList();

          for(var m in parsed){
            final log = m['log'] as AuditLogData;
            if(log.actionType.contains('JUAL')){
              omsetOwner += m['total'] as double;
              labaOwner += m['laba'] as double;
              final uid = log.userId;
              omsetPerSales[uid] = (omsetPerSales[uid]??0) + (m['total'] as double);
              labaPerSales[uid] = (labaPerSales[uid]??0) + (m['laba'] as double);
              final code = (m['oldV'] as Map)['code']??'UNKNOWN';
              omsetPerItem[code] = (omsetPerItem[code]??0) + (m['total'] as double);
            }
          }

          final topItems = omsetPerItem.entries.toList()..sort((a,b)=> b.value.compareTo(a.value));

          return Column(children: [
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isDark? const Color(0xFF1E293B) : Colors.black, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('OMSET OWNER ($_userFilter)', style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'Poppins')),
                    Text(_currency.format(omsetOwner), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
                    Text('Laba ${_currency.format(labaOwner)} | ${parsed.length} trx', style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'Poppins')),
                  ]),
                  if(topItems.isNotEmpty) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('TOP ITEM', style: TextStyle(color: Colors.white54, fontSize: 8, fontFamily: 'Poppins')),
                    Text(topItems.first.key, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    Text(_currency.format(topItems.first.value), style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'Poppins')),
                  ]),
                ]),
                const SizedBox(height: 8),
                SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: omsetPerSales.entries.map((e)=> Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(e.key.length>10? e.key.substring(0,10) : e.key, style: const TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'Poppins')),
                  Text(_currency.format(e.value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Poppins')),
                  Text('Laba ${_currency.format(labaPerSales[e.key]??0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontFamily: 'Poppins')),
                ]))).toList())),
              ]),
            ),
            Expanded(child: ListView.separated(
              itemCount: parsed.length,
              separatorBuilder: (_,__)=> const Divider(height: 1),
              itemBuilder: (c,i){
                final m = parsed[i];
                final log = m['log'] as AuditLogData;
                final oldV = m['oldV'] as Map; final newV = m['newV'] as Map;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(radius: 16, backgroundColor: log.actionType.contains('TIER_3')? Colors.orange : log.actionType.contains('TIER_2')? Colors.blue : log.actionType.contains('KULAK')? Colors.purple : Colors.green, child: Text(log.actionType.contains('KULAK')? 'B' : log.actionType.contains('TIER')? log.actionType.split('_').last : '!', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                  title: Text("${oldV['code']??''} | ${newV['customer']??''} | ${log.userId.length>6? log.userId.substring(0,6): log.userId} (${log.userRole})", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("Stok ${oldV['stock']}→${newV['stock']} (${newV['qty']} pcs) | HPP ${_currency.format(m['hpp'])} → Jual ${_currency.format(m['harga'])} | ${newV['payment']??''} | ${DateFormat('dd/MM HH:mm').format(log.createdAt)} | ${newV['ref']??''}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_currency.format(m['total']), style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: (m['laba'] as double) <0? Colors.red : Colors.green)),
                    Text("${_currency.format(m['laba'])} laba", style: TextStyle(fontFamily: 'Poppins', fontSize: 8, color: (m['laba'] as double) <0? Colors.red : Colors.green)),
                  ]),
                  onTap: ()=> showDialog(context: context, builder: (ctx)=> AlertDialog(title: Text("${log.actionType} - ${log.userId}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold)), content: SingleChildScrollView(child: Text("USER: ${log.userId}\nROLE: ${log.userRole}\n\n${log.description}\n\nOLD: ${log.oldValue}\n\nNEW: ${log.newValue}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 9))), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Tutup'))])),
                );
              },
            )),
          ]);
        },
      ),
    );
  }

  Widget _chip(String label, String value, Function(String) onTap, Color? color, [bool isPayment = false]){
    final isSelected = isPayment? _paymentFilter==value : _tierFilter==value;
    return Padding(padding: const EdgeInsets.only(right: 4), child: ChoiceChip(label: Text(label, style: const TextStyle(fontSize: 9, fontFamily: 'Poppins')), selected: isSelected, selectedColor: (color?? Colors.black).withOpacity(0.2), onSelected: (_)=> onTap(value)));
  }
}
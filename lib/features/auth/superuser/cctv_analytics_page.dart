import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/constant/audit_constant.dart';
import '../../../core/database/constant/constant_debt_status.dart';

enum MataElangMode { omset, item, supplier, hargaBocor, piutang, customerSultan, hargaHistory }

class CctvAnalyticsPage extends ConsumerStatefulWidget {
  const CctvAnalyticsPage({super.key});
  @override
  ConsumerState<CctvAnalyticsPage> createState() => _CctvAnalyticsPageState();
}

class _CctvAnalyticsPageState extends ConsumerState<CctvAnalyticsPage> {
  MataElangMode _mode = MataElangMode.omset;
  DateTimeRange? _dateRange;
  String _search = '';
  String _omsetFilter = 'OWNER_SALESMAN';
  String _selectedSalesmanId = 'SEMUA';
  String _selectedCategoryId = 'SEMUA';

  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFmt = DateFormat('dd/MM/yy HH:mm');
  final _dateShort = DateFormat('dd/MM');

  String _safe6(String s) => s.length <= 6? s : s.substring(0, 6);
  String _safeJson(Map<String, dynamic> m, String key) => (m[key]?.toString()?? '');

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('MATA ELANG - ${_mode.name.toUpperCase()}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 11)),
        actions: [
          IconButton(icon: const Icon(Icons.clear_all), onPressed: ()=> setState((){
            _search=''; _dateRange=null; _selectedCategoryId='SEMUA'; _omsetFilter='OWNER_SALESMAN';
          })),
        ],
      ),
      body: Column(children: [
        Container(
          color: isDark? const Color(0xFF0F172A) : Colors.black,
          padding: const EdgeInsets.all(6),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _modeChip('OMSET', MataElangMode.omset, Colors.greenAccent),
            _modeChip('ITEM', MataElangMode.item, Colors.orangeAccent),
            _modeChip('SUPPLIER', MataElangMode.supplier, Colors.purpleAccent),
            _modeChip('HARGA BOCOR', MataElangMode.hargaBocor, Colors.redAccent),
            _modeChip('PIUTANG', MataElangMode.piutang, Colors.yellowAccent),
            _modeChip('SULTAN', MataElangMode.customerSultan, Colors.blueAccent),
            _modeChip('HISTORI', MataElangMode.hargaHistory, Colors.tealAccent),
          ])),
        ),
        // FILTER ATAS - SINKRON KATEGORI DAO
        Container(
          padding: const EdgeInsets.all(8),
          color: isDark? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(
                decoration: InputDecoration(hintText: _getHint(), prefixIcon: const Icon(Icons.search, size: 18), isDense: true, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.all(10), filled: true, fillColor: Colors.white),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11),
                onChanged: (v)=> setState(()=> _search=v),
              )),
              const SizedBox(width: 6),
              ElevatedButton.icon(icon: const Icon(Icons.date_range, size: 16), label: Text(_dateRange==null? 'Tanggal' : "${_dateShort.format(_dateRange!.start)}-${_dateShort.format(_dateRange!.end)}", style: const TextStyle(fontSize: 9, fontFamily: 'Poppins')), onPressed: () async {
                final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now().add(const Duration(days: 1)));
                if(picked!=null) setState(()=> _dateRange=picked);
              }),
              if(_dateRange!=null) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: ()=> setState(()=> _dateRange=null)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: StreamBuilder<List<CategoryData>>(
                stream: db.categoryDao.watchAllCategories(),
                builder: (ctx, snap){
                  final cats = snap.data?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId, isDense: true, isExpanded: true,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8), filled: true, fillColor: Colors.white, labelText: 'Kategori'),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.black),
                    items: [
                      const DropdownMenuItem(value: 'SEMUA', child: Text('Semua Kategori')),
                    ...cats.map((c)=> DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v)=> setState(()=> _selectedCategoryId=v??'SEMUA'),
                  );
                },
              )),
              const SizedBox(width: 6),
              Expanded(child: DropdownButtonFormField<String>(
                value: _omsetFilter, isDense: true, isExpanded: true,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8), filled: true, fillColor: Colors.white, labelText: 'Omset By'),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.black),
                items: const [
                  DropdownMenuItem(value: 'OWNER_SALESMAN', child: Text('Owner + Salesman')),
                  DropdownMenuItem(value: 'OWNER', child: Text('Owner Saja')),
                  DropdownMenuItem(value: 'ALL_SALESMAN', child: Text('All Salesman')),
                ],
                onChanged: (v)=> setState(()=> _omsetFilter=v??'OWNER_SALESMAN'),
              )),
            ]),
          ]),
        ),
        Expanded(child: _buildContent(db, isDark)),
      ]),
    );
  }

  String _getHint(){
    switch(_mode){
      case MataElangMode.omset: return 'Cari faktur / customer / sales';
      case MataElangMode.item: return 'Cari kode / nama / customer / rak';
      case MataElangMode.supplier: return 'Cari supplier / kode';
      case MataElangMode.hargaBocor: return 'Cari kode / customer';
      case MataElangMode.piutang: return 'Cari customer / faktur';
      case MataElangMode.customerSultan: return 'Cari customer sultan';
      case MataElangMode.hargaHistory: return 'Cari kode / nama';
    }
  }

  Widget _modeChip(String label, MataElangMode mode, Color color){
    final sel = _mode==mode;
    return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.bold, color: sel? Colors.black : Colors.white)), selected: sel, selectedColor: color, backgroundColor: Colors.white10, onSelected: (_)=> setState(()=> _mode=mode)));
  }

  Widget _buildContent(LocalDatabase db, bool isDark){
    switch(_mode){
      case MataElangMode.omset: return _buildOmset(db, isDark);
      case MataElangMode.item: return _buildItem(db);
      case MataElangMode.supplier: return _buildSupplier(db);
      case MataElangMode.hargaBocor: return _buildHargaBocor(db);
      case MataElangMode.piutang: return _buildPiutang(db);
      case MataElangMode.customerSultan: return _buildCustomerSultan(db);
      case MataElangMode.hargaHistory: return _buildHargaHistory(db);
    }
  }

  // ================== FIX ERROR f['tgl'] as DateTime ==================
  Widget _buildOmset(LocalDatabase db, bool isDark){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        var logs = snap.data!.where((e)=> e.actionType.contains('JUAL')).toList();
        if(_selectedCategoryId!='SEMUA') logs = logs.where((e)=> (e.oldValue??'').contains(_selectedCategoryId) || (e.newValue??'').contains(_selectedCategoryId)).toList();
        if(_omsetFilter=='OWNER') logs = logs.where((e)=> e.userRole.toLowerCase().contains('owner')||e.userRole.toLowerCase().contains('superuser')).toList();
        if(_omsetFilter=='ALL_SALESMAN') logs = logs.where((e)=> e.userRole.toLowerCase().contains('salesman')).toList();

        final Map<String, List<AuditLogData>> byFaktur={};
        for(var l in logs){ byFaktur.putIfAbsent(l.referenceId??'NO-FAKTUR', ()=> []).add(l); }
        double grandJual=0, grandHpp=0;
        final fakturList = byFaktur.entries.map((e){
          double jual=0, hpp=0; String cust=''; String sales=''; DateTime tgl=e.value.first.createdAt; String status='LUNAS';
          for(var log in e.value){
            try{
              final newV=jsonDecode(log.newValue??'{}') as Map<String,dynamic>;
              final oldV=jsonDecode(log.oldValue??'{}') as Map<String,dynamic>;
              jual+=((newV['harga_jual']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs();
              hpp+=((newV['hpp_ma']?? oldV['hpp_ma']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs();
              cust=newV['customer']?.toString()??cust;
              sales=log.userId;
              status=newV['payment']?.toString()??status;
            }catch(_){}
          }
          grandJual+=jual; grandHpp+=hpp;
          // FIX: tgl sebagai DateTime, bukan Object?
          return <String, dynamic>{'faktur': e.key, 'cust': cust, 'sales': sales, 'tgl': tgl, 'jual': jual, 'hpp': hpp, 'laba': jual-hpp, 'status': status, 'count': e.value.length};
        }).toList()..sort((a,b)=> (b['tgl'] as DateTime).compareTo(a['tgl'] as DateTime));

        return Column(children: [
          Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("OMSET $_omsetFilter | ${_selectedCategoryId=='SEMUA'?'SEMUA KAT':'FILTER KAT'}", style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'Poppins')), Text(_currency.format(grandJual), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')), Text("Laba ${_currency.format(grandJual-grandHpp)} | ${fakturList.length} faktur", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'Poppins'))])])),
          Expanded(child: ListView.builder(itemCount: fakturList.length, itemBuilder: (c,i){
            final f=fakturList[i];
            final DateTime tgl = f['tgl'] as DateTime; // FIX ERROR The argument type 'Object?' can't be assigned to 'DateTime'
            return ListTile(dense: true, title: Text("${f['faktur']} | ${f['cust']} | ${_safe6(f['sales'].toString())}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("${_dateFmt.format(tgl)} | ${f['count']} item | ${f['status']} | Jual ${_currency.format(f['jual'])} HPP ${_currency.format(f['hpp'])}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8)), trailing: Text(_currency.format(f['laba']), style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: (f['laba'] as double)<0? Colors.red: Colors.green)));
          })),
        ]);
      },
    );
  }

  Widget _buildItem(LocalDatabase db){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        var logs = snap.data!;
        if(_selectedCategoryId!='SEMUA') logs = logs.where((e)=> (e.oldValue??'').contains(_selectedCategoryId) || (e.newValue??'').contains(_selectedCategoryId)).toList();
        return ListView.separated(itemCount: logs.length, separatorBuilder: (_,__)=> const Divider(height: 1), itemBuilder: (c,i){
          final log=logs[i];
          try{
            final oldV=jsonDecode(log.oldValue??'{}') as Map<String,dynamic>;
            final newV=jsonDecode(log.newValue??'{}') as Map<String,dynamic>;
            return ListTile(dense: true, title: Text("${_safeJson(oldV,'code')} ${_safeJson(oldV,'name')} | Cust:${_safeJson(newV,'customer')} | Tier:${_safeJson(newV,'tier')}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1), subtitle: Text("Tgl:${_dateFmt.format(log.createdAt)} | HPP MA ${_currency.format(newV['hpp_ma']?? oldV['hpp_ma']??0)} | Jual ${_currency.format(newV['harga_jual']??0)} x${newV['qty']??0} | Sales:${_safe6(log.userId)} | Faktur:${_safeJson(newV,'ref').isEmpty? (log.referenceId??''): _safeJson(newV,'ref')} | Rak:${_safeJson(newV,'rack').isEmpty? _safeJson(oldV,'rack'): _safeJson(newV,'rack')} | Stok ${oldV['stock']??''}->${newV['stock']??''}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8)));
          }catch(_){ return ListTile(title: Text(log.description, style: const TextStyle(fontFamily: 'Poppins', fontSize: 8))); }
        });
      },
    );
  }

  Widget _buildSupplier(LocalDatabase db){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        final Map<String, Map<String,dynamic>> perProduk={}; final cutoff=DateTime.now().subtract(const Duration(days: 60));
        for(var log in snap.data!){
          try{
            final oldV=jsonDecode(log.oldValue??'{}') as Map<String,dynamic>; final newV=jsonDecode(log.newValue??'{}') as Map<String,dynamic>; final code=oldV['code']?.toString()??'UNKNOWN';
            perProduk.putIfAbsent(code, ()=> {'code': code, 'name': oldV['name']??'', 'masuk':0.0, 'keluar':0.0, 'trx':0, 'jual':0.0, 'kategori': oldV['category']??''});
            if(log.actionType.contains('KULAK')) perProduk[code]!['masuk']=(perProduk[code]!['masuk'] as double)+((newV['qty']??0) as num).toDouble().abs();
            if(log.actionType.contains('JUAL') && log.createdAt.isAfter(cutoff)){ perProduk[code]!['keluar']=(perProduk[code]!['keluar'] as double)+((newV['qty']??0) as num).toDouble().abs(); perProduk[code]!['trx']=(perProduk[code]!['trx'] as int)+1; perProduk[code]!['jual']=(perProduk[code]!['jual'] as double)+((newV['harga_jual']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs(); }
          }catch(_){}
        }
        var list=perProduk.values.toList(); if(_selectedCategoryId!='SEMUA') list=list.where((e)=> (e['kategori'] as String).contains(_selectedCategoryId)).toList(); list.sort((a,b)=> (b['trx'] as int).compareTo(a['trx'] as int));
        return ListView.builder(itemCount: list.length, itemBuilder: (c,i){ final p=list[i]; final trx=p['trx'] as int; final isSlow=trx<3; final isFast=trx>10; return ListTile(dense: true, leading: CircleAvatar(radius: 14, backgroundColor: isSlow? Colors.red: isFast? Colors.green: Colors.grey, child: Text(isSlow? 'S': isFast? 'F':'N', style: const TextStyle(color: Colors.white, fontSize: 10))), title: Text("${p['code']} ${p['name']} | ${isSlow? 'SLOW': isFast? 'FAST':'NORMAL'} | $trx x /2bln", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("Masuk ${p['masuk']} | Keluar ${p['keluar']} | Turnover ${p['masuk']>0? ((p['keluar']/p['masuk'])*100).toStringAsFixed(1):0}% | Revenue ${_currency.format(p['jual'])}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8))); });
      },
    );
  }

  Widget _buildHargaBocor(LocalDatabase db){
    return StreamBuilder<List<FraudAlertData>>(stream: db.fraudAlertDao.watchAllAlerts(), builder: (ctx, snap){
      if(!snap.hasData) return const Center(child: CircularProgressIndicator());
      var alerts=snap.data!; if(_search.isNotEmpty) alerts=alerts.where((e)=> e.title.toLowerCase().contains(_search.toLowerCase()) || e.detailAnalysis.toLowerCase().contains(_search.toLowerCase())).toList();
      return ListView.separated(itemCount: alerts.length, separatorBuilder: (_,__)=> const Divider(height: 1), itemBuilder: (c,i){ final a=alerts[i]; return ListTile(dense: true, leading: Icon(a.severity==FraudSeverity.merah? Icons.warning: Icons.info, color: a.severity==FraudSeverity.merah? Colors.red: Colors.orange), title: Text("${a.title} | ${a.fraudCategory} | ${a.severity}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("${_dateFmt.format(a.createdAt)} | ${a.detailAnalysis}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8))); });
    });
  }

  Widget _buildPiutang(LocalDatabase db){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        var logs=snap.data!.where((e)=> (e.newValue??'').toUpperCase().contains('HUTANG') || (e.newValue??'').toUpperCase().contains('TEMPO') || (e.newValue??'').toLowerCase().contains('credit')).toList();
        final Map<String, double> piutang={}; final Map<String, DateTime> tgl={};
        for(var log in logs){ try{ final newV=jsonDecode(log.newValue??'{}') as Map<String,dynamic>; final cust=newV['customer']?.toString()??'UNKNOWN'; piutang[cust]=(piutang[cust]??0)+((newV['harga_jual']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs(); tgl[cust]=log.createdAt; }catch(_){} }
        final list=piutang.entries.toList()..sort((a,b)=> b.value.compareTo(a.value));
        return ListView.builder(itemCount: list.length, itemBuilder: (c,i){ final e=list[i]; final hari=DateTime.now().difference(tgl[e.key]??DateTime.now()).inDays; return ListTile(dense: true, title: Text("${e.key} | ${hari} hari | ${hari>60? 'MERAH >60': hari>=30? 'KUNING 30-45':'HIJAU 0-30'}", style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: hari>60? Colors.red: hari>=30? Colors.orange: Colors.green)), subtitle: Text("Terakhir ${_dateFmt.format(tgl[e.key]??DateTime.now())} | Status ${hari>60? DebtStatus.unpaid : DebtStatus.partial}"), trailing: Text(_currency.format(e.value), style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold))); });
      },
    );
  }

  Widget _buildCustomerSultan(LocalDatabase db){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        final Map<String, Map<String,dynamic>> perCust={};
        for(var log in snap.data!.where((e)=> e.actionType.contains('JUAL'))){
          try{
            final newV=jsonDecode(log.newValue??'{}') as Map<String,dynamic>; final cust=(newV['customer']?.toString()??'UNKNOWN').trim(); if(cust=='UNKNOWN' || cust.isEmpty) continue;
            final hj=((newV['harga_jual']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs(); final payment=(newV['payment']?.toString()??'LUNAS').toUpperCase(); final isCash=payment.contains('LUNAS')||payment.contains('CASH')||payment.contains('TUNAI')||payment==DebtStatus.paid.toUpperCase();
            perCust.putIfAbsent(cust, ()=> {'omset':0.0, 'trx':0, 'cash':0, 'hutang':0, 'lastDate': log.createdAt});
            perCust[cust]!['omset']=(perCust[cust]!['omset'] as double)+hj; perCust[cust]!['trx']=(perCust[cust]!['trx'] as int)+1;
            if(isCash) perCust[cust]!['cash']=(perCust[cust]!['cash'] as int)+1; else perCust[cust]!['hutang']=(perCust[cust]!['hutang'] as int)+1;
            if(log.createdAt.isAfter(perCust[cust]!['lastDate'] as DateTime)) perCust[cust]!['lastDate']=log.createdAt;
          }catch(_){}
        }
        var list=perCust.entries.map((e){
          final hari=DateTime.now().difference(e.value['lastDate'] as DateTime).inDays;
          final cash=e.value['cash'] as int; final isBintang=cash>=2 && hari<=30;
          String label; Color warna;
          if(isBintang){ label='HIJAU BINTANG ⭐ SULTAN - Cash ${cash}x + 0-30hr'; warna=Colors.green.shade700; }
          else if(hari>60){ label='MERAH - >60 HARI'; warna=Colors.red; }
          else if(hari>=30){ label='KUNING - 30-45 HARI'; warna=Colors.orange; }
          else { label='HIJAU - 0-30 HARI'; warna=Colors.green; }
          return {'customer': e.key, 'omset': e.value['omset'], 'trx': e.value['trx'], 'cash': cash, 'hutang': e.value['hutang'], 'hari': hari, 'label': label, 'warna': warna, 'isBintang': isBintang, 'lastDate': e.value['lastDate']};
        }).toList()..sort((a,b)=> (b['omset'] as double).compareTo(a['omset'] as double));

        return Column(children: [
          Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text("TOTAL ${list.length} CUSTOMER | SULTAN ⭐ ${list.where((e)=> e['isBintang']==true).length}", style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.bold))), Text(_currency.format(list.fold<double>(0, (p,e)=> p+(e['omset'] as double))), style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold))]),
          ),
          Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (c,i){
            final e=list[i]; final warna=e['warna'] as Color;
            return Container(color: (e['isBintang'] as bool)? Colors.green.withOpacity(0.08): null, child: ListTile(dense: true, leading: CircleAvatar(backgroundColor: warna, radius: 16, child: Icon((e['isBintang'] as bool)? Icons.star: Icons.person, color: Colors.white, size: 14)), title: Text("${i+1}. ${e['customer']} ${e['isBintang']==true? '⭐':''}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("${e['label']} | Omset ${_currency.format(e['omset'])} | ${e['trx']} trx | Cash ${e['cash']}x | Hutang ${e['hutang']}x | ${e['hari']} hari lalu", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8)), trailing: Text(_currency.format(e['omset']), style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: warna))));
          })),
        ]);
      },
    );
  }

  Widget _buildHargaHistory(LocalDatabase db){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        var logs=snap.data!.where((e)=> e.actionType.contains('KULAK') || e.actionType.contains('PRICE') || e.actionType.contains('UPDATE') || e.actionType.contains('EDIT')).toList();
        return ListView.separated(itemCount: logs.length, separatorBuilder: (_,__)=> const Divider(height: 1), itemBuilder: (c,i){
          final log=logs[i];
          try{
            final oldV=jsonDecode(log.oldValue??'{}') as Map<String,dynamic>; final newV=jsonDecode(log.newValue??'{}') as Map<String,dynamic>;
            return ListTile(dense: true, title: Text("${_safeJson(oldV,'code')} | HPP ${_safeJson(oldV,'hpp_ma')}->${_safeJson(newV,'hpp_ma').isEmpty? _safeJson(newV,'hpp_masuk'): _safeJson(newV,'hpp_ma')} | Jual ${_safeJson(oldV,'harga')}->${_safeJson(newV,'harga_jual')}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("${_dateFmt.format(log.createdAt)} | ${_safe6(log.userId)} | Kat:${_safeJson(oldV,'category')}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8)));
          }catch(_){ return ListTile(title: Text(log.description, style: const TextStyle(fontSize: 8))); }
        });
      },
    );
  }
}
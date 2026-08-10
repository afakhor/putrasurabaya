import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/constant/audit_constant.dart';

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
  String _tierFilter = 'SEMUA';
  String _paymentFilter = 'SEMUA';

  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFmt = DateFormat('dd/MM/yy HH:mm');
  final _dateShort = DateFormat('dd/MM');

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDatabaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('MATA ELANG - ${_mode.name.toUpperCase()}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 11)),
        actions: [
          IconButton(icon: const Icon(Icons.clear_all), onPressed: ()=> setState((){
            _search=''; _dateRange=null; _paymentFilter='SEMUA'; _tierFilter='SEMUA'; _selectedCategoryId='SEMUA';
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
            _modeChip('HISTORI HARGA', MataElangMode.hargaHistory, Colors.tealAccent),
          ])),
        ),
        // FILTER ATAS
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
              // CATEGORY DAO FILTER - PAKAI KATEGORI TABEL
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
                     ...cats.map((c)=> DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v)=> setState(()=> _selectedCategoryId=v??'SEMUA'),
                  );
                },
              )),
              const SizedBox(width: 6),
              if(_mode==MataElangMode.omset) Expanded(child: FutureBuilder<List<UserData>>(
                future: db.userDao.getAllUsers(),
                builder: (ctx, snap){
                  final sales = (snap.data?? []).where((u)=> u.role=='salesman').toList();
                  return DropdownButtonFormField<String>(
                    value: _omsetFilter, isDense: true, isExpanded: true,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8), filled: true, fillColor: Colors.white, labelText: 'Omset By'),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.black),
                    items: const [
                      DropdownMenuItem(value: 'OWNER_SALESMAN', child: Text('Owner + Salesman')),
                      DropdownMenuItem(value: 'OWNER', child: Text('Owner Saja')),
                      DropdownMenuItem(value: 'ALL_SALESMAN', child: Text('All Salesman')),
                      DropdownMenuItem(value: 'PER_SALESMAN', child: Text('Per Salesman')),
                    ],
                    onChanged: (v)=> setState(()=> _omsetFilter=v??'OWNER_SALESMAN'),
                  );
                },
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
      case MataElangMode.item: return 'Cari kode / nama / customer / rak / kategori';
      case MataElangMode.supplier: return 'Cari supplier / kode / nama barang';
      case MataElangMode.hargaBocor: return 'Cari kode / customer (auto deteksi bocor)';
      case MataElangMode.piutang: return 'Cari customer / faktur hutang';
      case MataElangMode.customerSultan: return 'Cari customer sultan';
      case MataElangMode.hargaHistory: return 'Cari kode / nama barang';
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

  Widget _buildOmset(LocalDatabase db, bool isDark){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        var logs = snap.data!.where((e)=> e.actionType.contains('JUAL')).toList();
        if(_selectedCategoryId!='SEMUA') logs = logs.where((e)=> (e.oldValue??'').contains(_selectedCategoryId) || (e.newValue??'').contains(_selectedCategoryId)).toList();
        if(_omsetFilter=='OWNER') logs = logs.where((e)=> e.userRole.contains('owner')||e.userRole.contains('superuser')).toList();
        if(_omsetFilter=='ALL_SALESMAN') logs = logs.where((e)=> e.userRole.contains('salesman')).toList();
        if(_omsetFilter=='PER_SALESMAN' && _selectedSalesmanId!='SEMUA') logs = logs.where((e)=> e.userId==_selectedSalesmanId).toList();

        final Map<String, List<AuditLogData>> byFaktur={};
        for(var l in logs){ byFaktur.putIfAbsent(l.referenceId??'NO-FAKTUR', ()=> []).add(l); }
        double grandJual=0, grandHpp=0;
        final fakturList = byFaktur.entries.map((e){
          double jual=0, hpp=0; String cust=''; String sales=''; DateTime tgl=e.value.first.createdAt; String status='LUNAS';
          for(var log in e.value){ final oldV=jsonDecode(log.oldValue??'{}'); final newV=jsonDecode(log.newValue??'{}'); jual+=((newV['harga_jual']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs(); hpp+=((newV['hpp_ma']?? oldV['hpp_ma']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs(); cust=newV['customer']??cust; sales=log.userId; status=newV['payment']??status; }
          grandJual+=jual; grandHpp+=hpp;
          return {'faktur': e.key, 'cust': cust, 'sales': sales, 'tgl': tgl, 'jual': jual, 'hpp': hpp, 'laba': jual-hpp, 'status': status, 'count': e.value.length};
        }).toList()..sort((a,b)=> (b['tgl'] as DateTime).compareTo(a['tgl'] as DateTime));

        return Column(children: [
          Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("OMSET $_omsetFilter", style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'Poppins')), Text(_currency.format(grandJual), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')), Text("Laba ${_currency.format(grandJual-grandHpp)} | ${fakturList.length} faktur", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'Poppins'))])])),
          Expanded(child: ListView.builder(itemCount: fakturList.length, itemBuilder: (c,i){ final f=fakturList[i]; return ListTile(dense: true, title: Text("${f['faktur']} | ${f['cust']} | ${f['sales'].toString().substring(0,6)}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("${_dateFmt.format(f['tgl'])} | ${f['count']} item | ${f['status']} | Jual ${_currency.format(f['jual'])} HPP ${_currency.format(f['hpp'])}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8)), trailing: Text(_currency.format(f['laba']), style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: (f['laba'] as double)<0? Colors.red: Colors.green))); })),
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
          final log=logs[i]; final oldV=jsonDecode(log.oldValue??'{}'); final newV=jsonDecode(log.newValue??'{}');
          return ListTile(dense: true, title: Text("${oldV['code']??''} ${oldV['name']??''} | Cust:${newV['customer']??''} | Tier:${newV['tier']??''} | Kategori:${oldV['category']?? newV['category']??''}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text("Tgl:${_dateFmt.format(log.createdAt)} | HPP MA ${_currency.format(newV['hpp_ma']?? oldV['hpp_ma']??0)} | Jual ${_currency.format(newV['harga_jual']??0)} x${newV['qty']??0} | Sales:${log.userId.substring(0,6)} | Faktur:${newV['ref']?? log.referenceId??''} | Rak:${newV['rack']?? oldV['rack']??''} | Stok ${oldV['stock']??''}->${newV['stock']??''}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8)));
        });
      },
    );
  }

  Widget _buildSupplier(LocalDatabase db){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        final Map<String, Map<String,dynamic>> perProduk={}; final cutoff=DateTime.now().subtract(const Duration(days: 60));
        for(var log in snap.data!){ final oldV=jsonDecode(log.oldValue??'{}'); final newV=jsonDecode(log.newValue??'{}'); final code=oldV['code']?.toString()??'UNKNOWN'; perProduk.putIfAbsent(code, ()=> {'code': code, 'name': oldV['name']??'', 'masuk':0.0, 'keluar':0.0, 'trx':0, 'jual':0.0, 'kategori': oldV['category']??''}); if(log.actionType.contains('KULAK')) perProduk[code]!['masuk']+=((newV['qty']??0) as num).toDouble().abs(); if(log.actionType.contains('JUAL') && log.createdAt.isAfter(cutoff)){ perProduk[code]!['keluar']+=((newV['qty']??0) as num).toDouble().abs(); perProduk[code]!['trx']+=1; perProduk[code]!['jual']+=((newV['harga_jual']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs(); } }
        var list=perProduk.values.toList(); if(_selectedCategoryId!='SEMUA') list=list.where((e)=> (e['kategori'] as String).contains(_selectedCategoryId)).toList(); list.sort((a,b)=> (b['trx'] as int).compareTo(a['trx'] as int));
        return ListView.builder(itemCount: list.length, itemBuilder: (c,i){ final p=list[i]; final trx=p['trx'] as int; final isSlow=trx<3; final isFast=trx>10; return ListTile(dense: true, leading: CircleAvatar(radius: 14, backgroundColor: isSlow? Colors.red: isFast? Colors.green: Colors.grey, child: Text(isSlow? 'S': isFast? 'F':'N', style: const TextStyle(color: Colors.white, fontSize: 10))), title: Text("${p['code']} ${p['name']} | ${isSlow? 'SLOW': isFast? 'FAST':'NORMAL'} | $trx x /2bln | Kat:${p['kategori']}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("Masuk ${p['masuk']} | Keluar ${p['keluar']} | Turnover ${p['masuk']>0? ((p['keluar']/p['masuk'])*100).toStringAsFixed(1):0}% | Revenue ${_currency.format(p['jual'])}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8))); });
      },
    );
  }

  Widget _buildHargaBocor(LocalDatabase db){
    return StreamBuilder<List<FraudAlertData>>(stream: db.fraudAlertDao.watchAllAlerts(), builder: (ctx, snap){
      if(!snap.hasData) return const Center(child: CircularProgressIndicator());
      var alerts=snap.data!; if(_search.isNotEmpty) alerts=alerts.where((e)=> e.title.toLowerCase().contains(_search.toLowerCase())).toList();
      return ListView.separated(itemCount: alerts.length, separatorBuilder: (_,__)=> const Divider(height: 1), itemBuilder: (c,i){ final a=alerts[i]; return ListTile(dense: true, leading: Icon(a.severity=='merah'? Icons.warning: Icons.info, color: a.severity=='merah'? Colors.red: Colors.orange), title: Text("${a.title} | ${a.fraudCategory} | ${a.severity}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("${_dateFmt.format(a.createdAt)} | ${a.detailAnalysis}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8))); });
    });
  }

  Widget _buildPiutang(LocalDatabase db){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        var logs=snap.data!.where((e)=> (e.newValue??'').toUpperCase().contains('HUTANG')).toList();
        final Map<String, double> piutang={}; final Map<String, DateTime> tgl={};
        for(var log in logs){ final newV=jsonDecode(log.newValue??'{}'); final cust=newV['customer']?.toString()??'UNKNOWN'; piutang[cust]=(piutang[cust]??0)+((newV['harga_jual']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs(); tgl[cust]=log.createdAt; }
        final list=piutang.entries.toList()..sort((a,b)=> b.value.compareTo(a.value));
        return ListView.builder(itemCount: list.length, itemBuilder: (c,i){ final e=list[i]; final hari=DateTime.now().difference(tgl[e.key]??DateTime.now()).inDays; return ListTile(dense: true, title: Text("${e.key} | ${hari} hari | ${hari>60? 'MERAH': hari>=30? 'KUNING':'HIJAU'}", style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: hari>60? Colors.red: hari>=30? Colors.orange: Colors.green)), subtitle: Text("Terakhir ${_dateFmt.format(tgl[e.key]??DateTime.now())}"), trailing: Text(_currency.format(e.value), style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold))); });
      },
    );
  }

  Widget _buildCustomerSultan(LocalDatabase db){
    return StreamBuilder<List<AuditLogData>>(stream: db.auditLogDao.watchCctvPerItem(keyword: _search.isEmpty? null : _search, start: _dateRange?.start, end: _dateRange?.end),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        final Map<String, Map<String,dynamic>> perCust={};
        for(var log in snap.data!.where((e)=> e.actionType.contains('JUAL'))){
          final newV=jsonDecode(log.newValue??'{}'); final cust=(newV['customer']?.toString()??'UNKNOWN').trim(); if(cust=='UNKNOWN') continue;
          final hj=((newV['harga_jual']??0) as num).toDouble()*((newV['qty']??0) as num).toDouble().abs(); final payment=(newV['payment']?.toString()??'LUNAS').toUpperCase(); final isCash=payment.contains('LUNAS')||payment.contains('CASH');
          perCust.putIfAbsent(cust, ()=> {'omset':0.0, 'trx':0, 'cash':0, 'hutang':0, 'lastDate': log.createdAt});
          perCust[cust]!['omset']=(perCust[cust]!['omset'] as double)+hj; perCust[cust]!['trx']=(perCust[cust]!['trx'] as int)+1;
          if(isCash) perCust[cust]!['cash']=(perCust[cust]!['cash'] as int)+1; else perCust[cust]!['hutang']=(perCust[cust]!['hutang'] as int)+1;
          if(log.createdAt.isAfter(perCust[cust]!['lastDate'] as DateTime)) perCust[cust]!['lastDate']=log.createdAt;
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
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("TOTAL ${list.length} CUSTOMER | SULTAN ⭐ ${list.where((e)=> e['isBintang']==true).length}", style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.bold)), Text(_currency.format(list.fold<double>(0, (p,e)=> p+(e['omset'] as double))), style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold))]),
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
        var logs=snap.data!.where((e)=> e.actionType.contains('KULAK') || e.actionType.contains('PRICE') || e.actionType.contains('UPDATE')).toList();
        return ListView.separated(itemCount: logs.length, separatorBuilder: (_,__)=> const Divider(height: 1), itemBuilder: (c,i){ final log=logs[i]; final oldV=jsonDecode(log.oldValue??'{}'); final newV=jsonDecode(log.newValue??'{}'); return ListTile(dense: true, title: Text("${oldV['code']??''} | HPP ${oldV['hpp_ma']??''}->${newV['hpp_ma']?? newV['hpp_masuk']??''} | Jual ${oldV['harga']??''}->${newV['harga_jual']??''}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold)), subtitle: Text("${_dateFmt.format(log.createdAt)} | ${log.userId.substring(0,6)} | Kat:${oldV['category']??''}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 8))); });
      },
    );
  }
}
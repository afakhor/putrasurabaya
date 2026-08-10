import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_database.dart';
import 'kartu_stock_page.dart';

class PersediaanStockBarangPage extends ConsumerStatefulWidget {
  final bool isPickMode;
  const PersediaanStockBarangPage({super.key, this.isPickMode=false});
  @override ConsumerState<PersediaanStockBarangPage> createState()=> _MasterState();
}

class _MasterState extends ConsumerState<PersediaanStockBarangPage> {
  String q='';
  String _selectedCatId = 'SEMUA';

  @override Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsStreamProvider);
    final db = ref.watch(localDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isPickMode?'Pilih Barang':'Master Barang'), backgroundColor: const Color(0xFF00A65A)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText:'Smart Search: SKU/Nama/Rak/Brand/Barcode',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true
                ),
                onChanged: (v)=> setState(()=> q=v.toLowerCase())
              ),
            ),
            const SizedBox(width: 8),
            // FILTER KATEGORI SINKRON DAO BARU
            StreamBuilder(
              stream: db.categoryDao.watchAllCategories(),
              builder: (c,snap){
                final cats = snap.data?? [];
                return DropdownButton<String>(
                  value: _selectedCatId,
                  hint: const Text('Kat'),
                  items: [
                    const DropdownMenuItem(value: 'SEMUA', child: Text('Semua')),
                   ...cats.map((e)=> DropdownMenuItem(value: e.id, child: Text(e.name))),
                  ],
                  onChanged: (v)=> setState(()=> _selectedCatId = v?? 'SEMUA'),
                );
              }
            ),
          ]),
        ),
        Expanded(child: productsAsync.when(
  data: (List<ProductData> list){
  var filtered = list;

  // Filter kategori
  if(_selectedCatId != 'SEMUA'){
    filtered = filtered.where((ProductData p)=> (p.categoryId) == _selectedCatId).toList();
  }

  // Filter search - FIX ERROR Object? & nullable
  if(q.isNotEmpty){
    final qq = q.toLowerCase();
    filtered = filtered.where((ProductData p){
      return p.name.toLowerCase().contains(qq) ||
             (p.code??'').toLowerCase().contains(qq) ||
             (p.barcode??'').toLowerCase().contains(qq) ||
             (p.rackLocation??'').toLowerCase().contains(qq) ||
             (p.brand??'').toLowerCase().contains(qq) ||
             (p.tags??'').toLowerCase().contains(qq) ||
             (p.description??'').toLowerCase().contains(qq);
    }).toList();
  }

            if(filtered.isEmpty) return const Center(child: Text('Barang tidak ada, tambah dulu'));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12,0,12,90),
              itemCount: filtered.length,
              itemBuilder: (c,i){
                final ProductData p = filtered[i]; // FIX: Explicit
                Color sc = p.stock<=0? Colors.red : p.stock<=p.minStock? Colors.orange : const Color(0xFF00A65A);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: sc.withOpacity(0.15), child: Icon(Icons.handyman, color: sc)),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13)),
                    subtitle: Text('SKU:${p.code} • ${p.stock} ${p.unit} • Rak:${p.rackLocation??'-'} • HPP:${p.buyPrice} • Kat:${p.categoryId??'-'}'),
                    trailing: widget.isPickMode? const Icon(Icons.chevron_right) : PopupMenuButton(
                      onSelected: (v) async {
                        if(v=='kartu') Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id)));
                        if(v=='hapus') await ref.read(localDatabaseProvider).productDao.softDeleteProduct(p.id);
                        if(v=='edit') Navigator.pop(context, p.id);
                      },
                      itemBuilder: (_)=> [const PopupMenuItem(value:'edit', child: Text('Edit')), const PopupMenuItem(value:'kartu', child: Text('Kartu Stok')), const PopupMenuItem(value:'hapus', child: Text('Hapus'))]
                    ),
                    onTap: () {
                      if(widget.isPickMode) Navigator.pop(context, p.id);
                      else Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id)));
                    },
                  )
                );
              }
            );
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Error: $e')),
        )),
      ]),
    );
  }
}
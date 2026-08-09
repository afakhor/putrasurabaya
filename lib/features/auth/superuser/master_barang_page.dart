import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/config.dart';
import '../../../core/utils/format_rupiah.dart';
import 'stock/kartu_stock_page.dart';
import 'stock/mutasi_stock_page.dart';
import 'product/product_page.dart';
import 'product/product_form_provider.dart';

class MasterBarangPage extends StatelessWidget {
  const MasterBarangPage({super.key});
  @override Widget build(BuildContext context) => const MasterBarangPageFinal();
}

final productFilterProvider = StateProvider<String>((ref)=> 'semua');
final productSortProvider = StateProvider<String>((ref)=> 'nama_az');
final turnoverProvider = FutureProvider<Map<String,double>>((ref) async {
  final db = ref.watch(localDatabaseProvider);
  return db.productDao.getTurnover30Days();
});

class MasterBarangPageFinal extends ConsumerStatefulWidget {
  const MasterBarangPageFinal({super.key});
  @override ConsumerState<MasterBarangPageFinal> createState()=> _MasterFinalState();
}

class _MasterFinalState extends ConsumerState<MasterBarangPageFinal> {
  String q='';
  @override Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final sort = ref.watch(productSortProvider);
    final turnoverAsync = ref.watch(turnoverProvider);
    final products = ref.watch(allProductsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Master Barang - Tier'), backgroundColor: const Color(0xFF00A65A), actions: [
        IconButton(icon: const Icon(Icons.receipt_long), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const MutasiStockPage()))),
        PopupMenuButton<String>(onSelected: (v)=> ref.read(productSortProvider.notifier).state=v, icon: const Icon(Icons.sort), itemBuilder: (_)=> const [
          PopupMenuItem(value:'nama_az', child: Text('Nama A-Z')),
          PopupMenuItem(value:'nama_za', child: Text('Nama Z-A')),
          PopupMenuItem(value:'stok_tersedikit', child: Text('Stok Tersedikit')),
          PopupMenuItem(value:'stok_terbanyak', child: Text('Stok Terbanyak')),
          PopupMenuItem(value:'fast_moving', child: Text('Fast Moving Turnover')),
        ]),
        IconButton(icon: const Icon(Icons.add_box), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const ProductPage()))),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText:'Smart Search: SKU/Nama/Rak/Brand/Barcode', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=> setState(()=> q=v.toLowerCase()))),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for(final f in ['semua','habis','menipis','fast']) Padding(padding: const EdgeInsets.only(left:8), child: ChoiceChip(label: Text(f.toUpperCase()), selected: filter==f, onSelected: (_)=> ref.read(productFilterProvider.notifier).state=f)),
        ])),
        Expanded(child: products.when(
          data: (list){
            final turnover = turnoverAsync.value??{};
            var f = list.where((p){
              final matchQ = q.isEmpty || p.name.toLowerCase().contains(q) || (p.code??'').toLowerCase().contains(q) || (p.barcode??'').toLowerCase().contains(q) || (p.rackLocation??'').toLowerCase().contains(q) || (p.brand??'').toLowerCase().contains(q);
              if(!matchQ) return false;
              if(filter=='habis') return p.stock<=0;
              if(filter=='menipis') return p.stock>0 && p.stock <= p.minStock;
              if(filter=='fast') return (turnover[p.id]??0) > 0;
              return true;
            }).toList();

            if(sort=='nama_az') f.sort((a,b)=> a.name.compareTo(b.name));
            if(sort=='nama_za') f.sort((a,b)=> b.name.compareTo(a.name));
            if(sort=='stok_tersedikit') f.sort((a,b)=> a.stock.compareTo(b.stock));
            if(sort=='stok_terbanyak') f.sort((a,b)=> b.stock.compareTo(a.stock));
            if(sort=='fast_moving'){ f.sort((a,b)=> (turnover[b.id]??0).compareTo(turnover[a.id]??0)); }

            if(f.isEmpty) return const Center(child: Text('Tidak ada barang'));
            return ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,90), itemCount: f.length, itemBuilder: (c,i){
              final p=f[i];
              final isHabis = p.stock<=0;
              final isMenipis = p.stock>0 && p.stock <= p.minStock;
              final turn = turnover[p.id]??0;
              Color sc = isHabis? Colors.red : isMenipis? Colors.orange : const Color(0xFF00A65A);
              return Padding(padding: const EdgeInsets.only(bottom:8), child: GlassCard(
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id))),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: sc.withOpacity(0.15), child: Icon(Icons.handyman, color: sc)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13, fontFamily:'Poppins')),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SKU:${p.code} | Stok:${p.stock} ${p.unit} | Rak:${p.rackLocation??'-'} | ${isHabis?'HABIS': isMenipis?'MENIPIS':'AMAN'}${turn>0?' • Turnover 30h:${turn.toStringAsFixed(0)}':''}', style: const TextStyle(fontSize:10)),
                    const SizedBox(height:2),
                    Text('HPP:${formatRupiah(p.buyPrice)} | Umum:${formatRupiah(p.sellPriceGeneral)} | T1:${formatRupiah(p.sellPriceTier1)} T2:${formatRupiah(p.sellPriceTier2)} T3:${formatRupiah(p.sellPriceTier3)}', style: const TextStyle(fontSize:9, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ]),
                  trailing: PopupMenuButton(onSelected: (v) async {
                    if(v=='edit'){
                      final prod = await ref.read(localDatabaseProvider).productDao.getProductById(p.id);
                      if(prod!=null && mounted){
                        ref.read(productFormProvider.notifier).setProduct(prod, [], [], []);
                        Navigator.push(context, MaterialPageRoute(builder: (_)=> const ProductPage()));
                      }
                    }
                    if(v=='hapus'){
                      final ok=await showDialog<bool>(context: context, builder: (_)=> AlertDialog(title: const Text('Hapus?'), content: Text('Hapus ${p.name}?'), actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Batal')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), child: const Text('Hapus'))]));
                      if(ok==true) ref.read(localDatabaseProvider).productDao.softDeleteProduct(p.id);
                    }
                    if(v=='kartu') Navigator.push(context, MaterialPageRoute(builder: (_)=> KartuStockPage(productId: p.id)));
                  }, itemBuilder: (_)=> const [PopupMenuItem(value:'edit', child: Text('Edit')), PopupMenuItem(value:'kartu', child: Text('Kartu Stok')), PopupMenuItem(value:'hapus', child: Text('Hapus'))]),
                ),
              ));
            });
          },
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Error: $e')),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00A65A),
        onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const ProductPage())),
        label: const Text('Tambah Perkakas', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
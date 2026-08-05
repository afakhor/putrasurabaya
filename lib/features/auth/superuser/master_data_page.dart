import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database.dart';
import 'kartu_stok_page.dart'; // <--- TAMBAHKAN INI

class MasterBarangPage extends ConsumerWidget {
  final bool isPickMode; // <--- TAMBAHKAN INI
  const MasterBarangPage({this.isPickMode = false, super.key}); // default false biar page lama tidak error

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider); // sesuaikan provider kamu

    return Scaffold(
      appBar: AppBar(
        title: Text(isPickMode? 'PILIH BARANG - KARTU STOK' : 'MASTER BARANG', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: isPickMode? Colors.indigo : null,
      ),
      body: productsAsync.when(
        data: (products) => ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_,__) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = products[i];
            return ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(p.stock.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              ),
              title: Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              subtitle: Text('${p.code} | Rak: ${p.rackLocation??"-"} | HPP: ${p.buyPrice}', style: const TextStyle(fontSize: 10)),
              trailing: isPickMode? const Icon(Icons.history_edu, color: Colors.indigo) : const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                if (isPickMode) {
                  // MODE PILIH UNTUK KARTU STOK
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => KartuStokPage(productId: p.id)));
                } else {
                  // MODE NORMAL - EDIT BARANG
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)));
                }
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
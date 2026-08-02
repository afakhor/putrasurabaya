import 'package:flutter/material.dart';

class MasterDataPage extends StatelessWidget {
  const MasterDataPage({super.key});
  @override
  Widget build(BuildContext context) {
    final menus = [
      {'title': 'Produk', 'icon': Icons.inventory_2, 'route': '/products'},
      {'title': 'Kategori', 'icon': Icons.category, 'route': '/categories'},
      {'title': 'Customer', 'icon': Icons.people_alt, 'route': '/customers'},
      {'title': 'Supplier', 'icon': Icons.local_shipping, 'route': '/suppliers'},
      {'title': 'Gudang', 'icon': Icons.warehouse, 'route': '/warehouse'},
      {'title': 'Promo', 'icon': Icons.local_offer, 'route': '/promo'},
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: menus.length,
      itemBuilder: (c,i) => Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // ICON SOLID - INI KUNCINYA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (m['color'] as Color).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(m['icon'] as IconData, size: 32, color: m['color'] as Color), // WARNA SOLID, SIZE BESAR
              ),
              const SizedBox(height: 12),
              Text(m['label'] as String, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14)),
            ],),
      ),
    );
  }
}
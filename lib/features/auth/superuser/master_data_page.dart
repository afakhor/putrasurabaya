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
          Icon(menus[i]['icon'] as IconData, size: 36, color: Colors.black),
          const SizedBox(height: 10),
          Text(menus[i]['title'] as String, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        ]),
      ),
    );
  }
}
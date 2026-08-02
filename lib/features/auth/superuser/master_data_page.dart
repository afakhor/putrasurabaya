import 'package:flutter/material.dart';

class MasterDataPage extends StatelessWidget {
  const MasterDataPage({super.key});
  @override
  Widget build(BuildContext context) {
    final menus = [
      {'title': 'Produk', 'icon': Icons.inventory_2, 'color': Colors.blue, 'route': '/products'},
      {'title': 'Kategori', 'icon': Icons.category, 'color': Colors.orange, 'route': '/categories'},
      {'title': 'Customer', 'icon': Icons.people_alt, 'color': Colors.green, 'route': '/customers'},
      {'title': 'Supplier', 'icon': Icons.local_shipping, 'color': Colors.purple, 'route': '/suppliers'},
      {'title': 'Gudang', 'icon': Icons.warehouse, 'color': Colors.brown, 'route': '/warehouse'},
      {'title': 'Promo', 'icon': Icons.local_offer, 'color': Colors.teal, 'route': '/promo'},
    ];
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1),
        itemCount: menus.length,
        itemBuilder: (c, i) {
          final m = menus[i];
          return InkWell(
            onTap: () {
              if (m['route'] != null) {
                // Navigator.pushNamed(context, m['route'] as String);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buka ${m['title']}')));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92), // KACA TRANSPARAN TETAP
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (m['color'] as Color).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(m['icon'] as IconData, size: 32, color: m['color'] as Color), // ICON SOLID
                  ),
                  const SizedBox(height: 12),
                  Text(m['title'] as String, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
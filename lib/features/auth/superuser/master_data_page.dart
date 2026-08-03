import 'package:flutter/material.dart';
import '../../../core/utils/config.dart';

class MasterDataPage extends StatelessWidget {
  const MasterDataPage({super.key});
  @override Widget build(BuildContext context) {
    final menus = [
      {'title': 'Produk', 'icon': Icons.inventory_2, 'color': Colors.blue},
      {'title': 'Kategori', 'icon': Icons.category, 'color': Colors.orange},
      {'title': 'Customer', 'icon': Icons.people_alt, 'color': Colors.green},
      {'title': 'Supplier', 'icon': Icons.local_shipping, 'color': Colors.purple},
      {'title': 'Gudang', 'icon': Icons.warehouse, 'color': Colors.brown},
      {'title': 'Promo', 'icon': Icons.local_offer, 'color': Colors.teal},
    ];
    return Scaffold(backgroundColor: Colors.transparent, body: GridView.builder(padding: EdgeInsets.all(16), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1), itemCount: menus.length, itemBuilder: (c,i){ final m=menus[i]; return GlassCard(onTap: ()=> ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buka ${m['title']}'))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: (m['color'] as Color).withOpacity(0.15), shape: BoxShape.circle), child: Icon(m['icon'] as IconData, size: 32, color: m['color'] as Color)), SizedBox(height: 12), Text(m['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))])); }));
  }
}
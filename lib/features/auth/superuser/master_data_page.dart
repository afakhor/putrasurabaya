import 'package:flutter/material.dart';
import '../../../core/utils/config.dart';
import 'product/product_page.dart';
import 'manage_users_page.dart';
import 'audit_fraud_page.dart';

class MasterDataPage extends StatelessWidget {
  const MasterDataPage({super.key});
  @override Widget build(BuildContext context) {
    final menus = [
      {'title':'Produk Perkakas\n24 Kategori','icon':Icons.handyman,'color':Colors.orange,'page': const ProductPage()},
      {'title':'Kategori\nPerkakas','icon':Icons.category,'color':Colors.blue,'page': null},
      {'title':'Supplier','icon':Icons.local_shipping,'color':Colors.purple,'page': null},
      {'title':'Customer','icon':Icons.people,'color':Colors.green,'page': null},
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, crossAxisSpacing:12, mainAxisSpacing:12, childAspectRatio:1.1),
        itemCount: menus.length,
        itemBuilder: (c,i){
          final m=menus[i];
          return GlassCard(
            onTap: (){
              if(m['page']!=null){ Navigator.push(context, MaterialPageRoute(builder: (_)=> m['page'] as Widget)); }
              else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buka ${m['title']}'))); }
            },
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: (m['color'] as Color).withOpacity(0.15), shape: BoxShape.circle), child: Icon(m['icon'] as IconData, size:32, color: m['color'] as Color)),
              const SizedBox(height:12),
              Text(m['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize:12)),
            ]),
          );
        },
      ),
    );
  }
}
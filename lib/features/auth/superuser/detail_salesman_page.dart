import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/daos/user_dao.dart';
import '../../../core/utils/config.dart';

class DetailSalesmanPage extends ConsumerStatefulWidget {
  final UserData user;
  const DetailSalesmanPage({super.key, required this.user});
  @override ConsumerState<DetailSalesmanPage> createState() => _DetailSalesmanPageState();
}

class _DetailSalesmanPageState extends ConsumerState<DetailSalesmanPage> {
  late UserData currentUser;
  @override void initState() { super.initState(); currentUser = widget.user; }

  Future<void> _refresh() async {
    final dao = ref.read(userDaoProvider);
    final updated = await dao.getUserById(currentUser.id);
    if (updated!= null) setState(() => currentUser = updated);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('API Key Salesman', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GlassCard(child: Column(children: [
          CircleAvatar(radius: 35, backgroundColor: Colors.black, child: Text(currentUser.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28))),
          const SizedBox(height: 10),
          Text(currentUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
          Text('${currentUser.role} • ${currentUser.salesArea?? "-"}', style: const TextStyle(fontSize: 12)),
        ])),
        const SizedBox(height: 16),
        GlassCard(child: Column(children: [
          const Text('SCAN QR UNTUK LOGIN SALESMAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 16),
          if (currentUser.apiKey!= null)
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: QrImageView(data: currentUser.apiKey!, version: QrVersions.auto, size: 220)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: SelectableText(currentUser.apiKey?? '-', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: currentUser.apiKey?? '')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); }),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Regenerate Key Baru'), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), onPressed: () async { final dao = ref.read(userDaoProvider); await dao.regenerateApiKey(currentUser.id); await _refresh(); })),
        ])),
      ]),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/daos/user_dao.dart';

class DetailSalesmanPage extends ConsumerStatefulWidget {
  final UserData user;
  const DetailSalesmanPage({super.key, required this.user});

  @override
  ConsumerState<DetailSalesmanPage> createState() => _DetailSalesmanPageState();
}

class _DetailSalesmanPageState extends ConsumerState<DetailSalesmanPage> {
  late UserData currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  Future<void> _refreshUser() async {
    final dao = ref.read(userDaoProvider);
    final updated = await dao.getUserById(currentUser.id);
    if (updated!= null) {
      setState(() => currentUser = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: isDark? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.85),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark? Colors.white : Colors.black),
        title: Text(
          'API Key Salesman',
          style: TextStyle(color: isDark? Colors.white : Colors.black, fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HEADER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  CircleAvatar(radius: 35, backgroundColor: Colors.black, child: Text(currentUser.name.isNotEmpty? currentUser.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 28))),
                  const SizedBox(height: 12),
                  Text(currentUser.name, style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  Text('${currentUser.role.toUpperCase()} • ${currentUser.salesArea?? 'No Area'} • ${currentUser.status}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: currentUser.status == 'aktif'? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Text(currentUser.status.toUpperCase(), style: TextStyle(color: currentUser.status == 'aktif'? Colors.green.shade800 : Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // QR CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text('SCAN QR UNTUK LOGIN SALESMAN', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  if (currentUser.apiKey!= null && currentUser.apiKey!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
                      child: QrImageView(
                        data: currentUser.apiKey!,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      ),
                    )
                  else
                    const Text('Belum ada API Key', style: TextStyle(color: Colors.black)),
                  const SizedBox(height: 20),

                  // API KEY TEXT FIELD + COPY
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('API KEY', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              SelectableText(currentUser.apiKey?? '-', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.black),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: currentUser.apiKey?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key dicopy ke clipboard!'), backgroundColor: Colors.black));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TOMBOL AKSI
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy_all, color: Colors.black, size: 18),
                          label: const Text('Copy Key', style: TextStyle(color: Colors.black, fontSize: 12)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: currentUser.apiKey?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key dicopy!')));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Regenerate', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Regenerate API Key?', style: TextStyle(color: Colors.black)),
                              content: const Text('API Key lama tidak akan bisa dipakai lagi. Salesman harus scan ulang.', style: TextStyle(color: Colors.black54)),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black), onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Buat Baru', style: TextStyle(color: Colors.white)))],
                            ));
                            if (confirm == true) {
                              final dao = ref.read(userDaoProvider);
                              await dao.regenerateApiKey(currentUser.id);
                              await _refreshUser();
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key baru berhasil dibuat!'), backgroundColor: Colors.green));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // INFO CARA PAKAI
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text('Cara pakai:\n1. Buka HP Salesman > Tab Kasir/Sales > Scan QR\n2. Atau paste manual KEY-XXXX di kolom API Key', style: TextStyle(color: Colors.black87, fontSize: 11))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // INFO TAMBAHAN PIN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Info Login Lainnya', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Text('PIN: ${currentUser.pinCode?? '-'}', style: const TextStyle(color: Colors.black87, fontSize: 13, fontFamily: 'monospace')),
                Text('ID: ${currentUser.id}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'auth_provider.dart';
import 'role_router.dart';

class LoginMainPage extends ConsumerStatefulWidget {
  const LoginMainPage({super.key});

  @override
  ConsumerState<LoginMainPage> createState() => _LoginMainPageState();
}

class _LoginMainPageState extends ConsumerState<LoginMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controller Owner
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // Controller Kasir/Salesman
  final _pinCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  bool _isScanMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pinCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dengerin hasil login -> auto pindah halaman sesuai role
    ref.listen<AsyncValue>(authNotifierProvider, (prev, next) {
      next.when(
        data: (user) {
          if (user != null) {
            final home = getHomeByRole(user as dynamic);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => home),
            );
          }
        },
        error: (err, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err.toString()), backgroundColor: Colors.red),
          );
        },
        loading: () {},
      );
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.store_rounded, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            const Text('UD PUTRA KASIR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Login iPOS 5 Style', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // TAB SELECTOR
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Owner / Admin', icon: Icon(Icons.admin_panel_settings)),
                Tab(text: 'Kasir / Sales', icon: Icon(Icons.person_pin)),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ================= TAB 1: OWNER / ADMIN =================
                  _buildOwnerTab(isLoading),

                  // ================= TAB 2: KASIR / SALESMAN =================
                  _buildKasirSalesTab(isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerTab(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _userCtrl,
            decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : () {
                ref.read(authNotifierProvider.notifier).loginByPassword(_userCtrl.text.trim(), _passCtrl.text.trim());
              },
              child: isLoading ? const CircularProgressIndicator() : const Text('MASUK SEBAGAI OWNER/ADMIN'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKasirSalesTab(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Switch Scan vs Input
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('PIN / Paste'), icon: Icon(Icons.keyboard)),
              ButtonSegment(value: true, label: Text('Scan QR'), icon: Icon(Icons.qr_code_scanner)),
            ],
            selected: {_isScanMode},
            onSelectionChanged: (v) => setState(() => _isScanMode = v.first),
          ),
          const SizedBox(height: 20),

          if (!_isScanMode) ...[
            // INPUT PIN KASIR
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'PIN Kasir (6 Digit)', prefixIcon: Icon(Icons.pin), border: OutlineInputBorder()),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading || _pinCtrl.text.length != 6 ? null : () {
                  ref.read(authNotifierProvider.notifier).loginByPin(_pinCtrl.text.trim());
                },
                child: const Text('MASUK PAKAI PIN'),
              ),
            ),
            const Divider(height: 30),
            // INPUT API KEY SALESMAN
            TextField(
              controller: _apiKeyCtrl,
              decoration: InputDecoration(
                labelText: 'API Key Salesman (KEY-...)',
                prefixIcon: const Icon(Icons.vpn_key),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) _apiKeyCtrl.text = data!.text!;
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading ? null : () {
                  ref.read(authNotifierProvider.notifier).loginByApiKey(_apiKeyCtrl.text.trim());
                },
                child: const Text('MASUK PAKAI API KEY'),
              ),
            ),
          ] else ...[
            // MODE SCAN QR
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  onDetect: (capture) {
                    final code = capture.barcodes.first.rawValue;
                    if (code != null && code.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      setState(() => _isScanMode = false);
                      _apiKeyCtrl.text = code;
                      ref.read(authNotifierProvider.notifier).loginByApiKey(code);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Arahkan kamera ke QR API Key dari HP Owner'),
          ]
        ],
      ),
    );
  }
}
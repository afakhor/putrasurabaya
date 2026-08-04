import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/local_database.dart';
import '../../../../core/database/tables/category_table.dart';
import 'product_form_provider.dart';

class MasterFabPerkakas extends ConsumerStatefulWidget {
  final Function(BuildContext, {ProductData? product})? onOpenForm;
  const MasterFabPerkakas({super.key, this.onOpenForm});
  @override ConsumerState<MasterFabPerkakas> createState() => _MasterFabPerkakasState();
}

class _MasterFabPerkakasState extends ConsumerState<MasterFabPerkakas> with TickerProviderStateMixin {
  late AnimationController mainC;
  late AnimationController subC;
  int? selected;

  @override void initState() {
    super.initState();
    mainC = AnimationController(duration: const Duration(milliseconds: 280), vsync: this);
    subC = AnimationController(duration: const Duration(milliseconds: 220), vsync: this);
  }

  @override void dispose() {
    mainC.dispose();
    subC.dispose();
    super.dispose();
  }

  void closeFab() {
    subC.reverse();
    mainC.reverse();
    setState(() { selected = null; });
  }

  void toggleFab() {
    if (mainC.isCompleted) { closeFab(); } else { mainC.forward(); }
  }

  @override Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 420,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (selected == 1) ...buildEmergency(),
          ...buildMain(),
          FloatingActionButton(
            heroTag: 'master_fab',
            backgroundColor: mainC.isCompleted ? Colors.black87 : const Color(0xFF007F00),
            onPressed: toggleFab,
            child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: mainC),
          ),
        ],
      ),
    );
  }

  List<Widget> buildMain() {
    const r = 115.0;
    return List.generate(3, (i) {
      final ang = (pi / 2) * (i / 2);
      return AnimatedBuilder(
        animation: mainC,
        builder: (_, __) {
          final p = mainC.value;
          final dx = -r * p * cos(ang);
          final dy = -r * p * sin(ang);
          Color col;
          IconData ic;
          if (i == 0) { col = const Color(0xFF00A65A); ic = Icons.add_box_rounded; }
          else if (i == 1) { col = Colors.red.shade800; ic = Icons.warning_amber_rounded; }
          else { col = Colors.amber.shade900; ic = Icons.grid_view_rounded; }
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: p,
              child: FloatingActionButton.small(
                heroTag: 'main_$i',
                backgroundColor: col,
                onPressed: () {
                  if (i == 0) {
                    closeFab();
                    ref.invalidate(productFormProvider);
                    if (widget.onOpenForm != null) widget.onOpenForm!(context);
                  } else if (i == 2) {
                    closeFab();
                    showQuickGrid();
                  } else {
                    if (selected == i) { subC.reverse(); setState(() { selected = null; }); }
                    else { setState(() { selected = i; }); subC.forward(from: 0); }
                  }
                },
                child: Icon(ic, color: Colors.white),
              ),
            ),
          );
        },
      );
    });
  }

  List<Widget> buildEmergency() {
    const pr = 115.0;
    const sr = 75.0;
    final pa = pi / 4;
    final pdx = -pr * cos(pa);
    final pdy = -pr * sin(pa);
    return List.generate(3, (j) {
      const spread = pi / 3;
      final start = pa - spread / 2;
      final step = spread / 2;
      final cur = start + j * step;
      Color col;
      IconData ic;
      if (j == 0) { col = Colors.red.shade700; ic = Icons.gavel_rounded; }
      else if (j == 1) { col = Colors.amber.shade900; ic = Icons.monetization_on_rounded; }
      else { col = Colors.purple.shade700; ic = Icons.history; }
      return AnimatedBuilder(
        animation: subC,
        builder: (_, __) {
          final p = subC.value;
          final dx = pdx - sr * p * cos(cur);
          final dy = pdy - sr * p * sin(cur);
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: p,
              child: FloatingActionButton.small(
                heroTag: 'em_$j',
                backgroundColor: col,
                onPressed: () {
                  closeFab();
                  if (j == 0) koreksiStok();
                  if (j == 1) ubahHarga();
                  if (j == 2) lihatMutasi();
                },
                child: Icon(ic, color: Colors.white, size: 18),
              ),
            ),
          );
        },
      );
    });
  }

  void showQuickGrid() {
    final db = ref.read(localDatabaseProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        children: [
          quickItem(ctx, 'Kategori', Icons.category, Colors.blue, addKategori),
          quickItem(ctx, 'Sub', Icons.layers, Colors.deepOrange, addSubKategori),
          quickItem(ctx, 'Supplier', Icons.local_shipping, Colors.green, () => addSupplier(db)),
          quickItem(ctx, 'Customer', Icons.people, Colors.teal, () => addCustomer(db)),
        ],
      ),
    );
  }

  Widget quickItem(BuildContext ctx, String title, IconData ic, Color col, Function() act) {
    return InkWell(
      onTap: () { Navigator.pop(ctx); act(); },
      child: Column(children: [CircleAvatar(backgroundColor: col.withOpacity(0.15), child: Icon(ic, color: col)), const SizedBox(height: 6), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
    );
  }

  void addKategori() async {
    final c = TextEditingController();
    final res = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('Kategori Baru'), content: TextField(controller: c), actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Simpan'))]));
    if (res != null && res.isNotEmpty) {
      final dao = ref.read(localDatabaseProvider).categoryDao;
      await dao.createCategory(name: res, type: CategoryType.product, sortOrder: DateTime.now().millisecond);
    }
  }

  void addSubKategori() async {}
  void addSupplier(LocalDatabase db) async {}
  void addCustomer(LocalDatabase db) async {}
  void koreksiStok() {}
  void ubahHarga() {}
  void lihatMutasi() {}
}
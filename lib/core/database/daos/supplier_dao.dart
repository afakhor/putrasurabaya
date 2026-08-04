import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/supplier_table.dart';
part 'supplier_dao.g.dart';

@DriftAccessor(tables: [Suppliers])
class SupplierDao extends DatabaseAccessor<LocalDatabase> with _$SupplierDaoMixin {
  SupplierDao(LocalDatabase db): super(db);
  Future<List<SupplierData>> getAll() => select(suppliers).get();
  Stream<List<SupplierData>> watchAll() => select(suppliers).watch();
  Future<String> createSupplier({required String name}) async {
    final id = 'SPL-${DateTime.now().millisecondsSinceEpoch}';
    await into(suppliers).insert(SuppliersCompanion.insert(id: id, name: name, status: const Value('aktif')));
    return id;
  }
}
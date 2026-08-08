import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/supplier_table.dart';

part 'supplier_dao.g.dart';

@DriftAccessor(tables: [Suppliers])
class SupplierDao extends DatabaseAccessor<LocalDatabase> with _$SupplierDaoMixin {
  SupplierDao(LocalDatabase db): super(db);

  Stream<List<SupplierData>> watchAll() => (select(suppliers)..where((s)=> s.status.equals('aktif'))..orderBy([(s)=> OrderingTerm.asc(s.name)])).watch();

  Future<String> createSupplierFull({
    required String name, String? phone, String? wa, String? address, String? kota, String? picName,
    String category='Perkakas Tangan', String type='Grosir',
  }) async {
    final id = 'SUP-${DateTime.now().millisecondsSinceEpoch}';
    await into(suppliers).insert(SuppliersCompanion.insert(
      id: id, code: Value('SUP-${id.substring(4,9)}'), name: name,
      phone: Value(phone), wa: Value(wa), address: Value(address), kota: Value(kota), picName: Value(picName),
      category: Value(category), type: Value(type), status: const Value('aktif'), isSynced: const Value(false),
    ));
    return id;
  }
}
import 'package:drift/drift.dart';

@DataClassName('SupplierData')
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get leadTimeDays => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}

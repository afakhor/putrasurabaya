import 'package:drift/drift.dart';

@DataClassName('CustomerData')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get totalDebt => real().withDefault(const Constant(0))();

  @override 
  Set<Column> get primaryKey => {id};
}

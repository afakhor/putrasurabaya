import 'package:drift/drift.dart';

@DataClassName('CustomerData')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get totalDebt => real().withDefault(const Constant(0.0))(); // <--- Ubah 0 jadi 0.0

  @override 
  Set<Column> get primaryKey => {id};
}

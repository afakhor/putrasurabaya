import 'package:drift/drift.dart';

@DataClassName('CustomerData')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  
  /// Menyimpan akumulasi total piutang/hutang pelanggan
  RealColumn get totalDebt => real().withDefault(const Constant(0.0))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

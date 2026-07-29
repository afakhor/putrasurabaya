import 'package:drift/drift.dart';

@DataClassName('UserData')
class Users extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get role => text()(); // 'superuser' / 'salesman'
  TextColumn get apiKey => text().nullable()(); 
  TextColumn get phone => text().nullable()();
  TextColumn get salesArea => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get passwordHash => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' / 'suspended'
  BoolColumn get canEditPrice => boolean().withDefault(const Constant(false))();
  BoolColumn get canDeleteTransaction => boolean().withDefault(const Constant(false))();

  @override 
  Set<Column> get primaryKey => {id};
}

@DataClassName('ShiftKasirData')
class ShiftKasir extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get initialCash => real().withDefault(const Constant(0.0))();
  RealColumn get expectedCash => real().withDefault(const Constant(0.0))();
  RealColumn get actualCash => real().nullable()();
  RealColumn get cashDifference => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))(); // 'open' / 'closed'

  @override 
  Set<Column> get primaryKey => {id};
}

import 'package:drift/drift.dart';

@DataClassName('SupplierData')
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get picName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get wa => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get kelurahan => text().nullable()();
  TextColumn get kota => text().nullable()();
  
  // KATEGORI META SUPPLIER
  TextColumn get category => text().withDefault(const Constant('Perkakas Tangan'))(); // Perkakas Tangan, Listrik, Pipa, Cat, Baut
  TextColumn get type => text().withDefault(const Constant('Grosir'))(); // Pabrik, Distributor, Grosir, Agen, Importir, Lokal
  TextColumn get paymentTerm => text().withDefault(const Constant('Tunai'))();
  
  RealColumn get totalPayable => real().withDefault(const Constant(0.0))();
  IntColumn get leadTimeDays => integer().withDefault(const Constant(3))();
  TextColumn get status => text().withDefault(const Constant('aktif'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}
import 'package:drift/drift.dart';

@DataClassName('CustomerData')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get wa => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get kelurahan => text().nullable()();
  TextColumn get kota => text().nullable()();
  TextColumn get kelas => text().withDefault(const Constant('Retail'))();
  TextColumn get paymentType => text().withDefault(const Constant('Tunai'))();
  TextColumn get tierHarga => text().withDefault(const Constant('Umum'))();
  TextColumn get categoryId => text().nullable()();
  RealColumn get plafonHutang => real().withDefault(const Constant(0))();
  RealColumn get sisaHutang => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))();
  
  // TAMBAHAN RECEIVABLES.md V.5 & VIII
  TextColumn get blacklistReason => text().nullable()(); // alasan blacklist
  TextColumn get blacklistBy => text().nullable()(); // ownerId
  DateTimeColumn get blacklistAt => dateTime().nullable()();
  TextColumn get kartuDosa => text().nullable()(); // JSON: [{tgl, item ngendap, janji bayar, sales}]

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}
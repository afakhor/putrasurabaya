import 'package:drift/drift.dart';

@DataClassName('CustomerData')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  
  // KONTAK LENGKAP
  TextColumn get phone => text().nullable()();
  TextColumn get wa => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get kelurahan => text().nullable()();
  TextColumn get kota => text().nullable()();
  
  // KATEGORI META CUSTOMER
  TextColumn get kelas => text().withDefault(const Constant('Retail'))(); // Retail, Member, Grosir, Distributor, Project, Toko, Bengkel
  TextColumn get paymentType => text().withDefault(const Constant('Tunai'))(); // Tunai, Transfer, Tempo 7, Tempo 14, Tempo 30, Bon
  TextColumn get tierHarga => text().withDefault(const Constant('Umum'))(); // Umum, Tier1, Tier2, Tier3
  TextColumn get categoryId => text().nullable()(); // link ke Categories untuk filter
  
  RealColumn get plafonHutang => real().withDefault(const Constant(0))();
  RealColumn get sisaHutang => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}
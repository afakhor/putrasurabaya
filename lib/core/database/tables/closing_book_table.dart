import 'package:drift/drift.dart';

@DataClassName('ClosingBookData')
class ClosingBooks extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get periode => text()(); // AWAL_AKHIR, BULANAN, TAHUNAN, CUSTOM
  TextColumn get periodeLabel => text().withDefault(const Constant(''))(); // "Jan 2024 - Dec 2024"
  
  // LABA RUGI REAL TIME
  RealColumn get omset => real().withDefault(const Constant(0))();
  RealColumn get hpp => real().withDefault(const Constant(0))();
  RealColumn get totalBeli => real().withDefault(const Constant(0))();
  RealColumn get biaya => real().withDefault(const Constant(0))();
  RealColumn get labaKotor => real().withDefault(const Constant(0))();
  RealColumn get labaBersih => real().withDefault(const Constant(0))();
  
  // NERACA REAL TIME
  RealColumn get stockAkhir => real().withDefault(const Constant(0))();
  RealColumn get stockAwal => real().withDefault(const Constant(0))();
  RealColumn get piutangAkhir => real().withDefault(const Constant(0))();
  RealColumn get hutangAkhir => real().withDefault(const Constant(0))();
  RealColumn get modalAkhir => real().withDefault(const Constant(0))();
  
  // BREAKDOWN BY CATEGORY - ANTI REKAP ULANG
  TextColumn get categoryBreakdownJson => text().withDefault(const Constant('{}'))(); // {"Cat": {"omset": 100, "laba": 20}}
  TextColumn get topCategoryId => text().nullable()();
  TextColumn get worstCategoryId => text().nullable()();
  
  // STATISTIK
  IntColumn get totalTransaksi => integer().withDefault(const Constant(0))();
  IntColumn get totalSkuTerjual => integer().withDefault(const Constant(0))();
  IntColumn get totalSkuMati => integer().withDefault(const Constant(0))();
  IntColumn get totalCustomer => integer().withDefault(const Constant(0))();
  
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  TextColumn get lockedBy => text().nullable()();
  DateTimeColumn get lockedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override Set<Column> get primaryKey => {id};
}

// TABLE SNAPSHOT PER CATEGORY - BIAR TIDAK HITUNG ULANG TERUS
@DataClassName('CategoryReportSnapshotData')
class CategoryReportSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get closingBookId => text().references(ClosingBooks, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get categoryName => text()();
  RealColumn get omset => real().withDefault(const Constant(0))();
  RealColumn get hpp => real().withDefault(const Constant(0))();
  RealColumn get laba => real().withDefault(const Constant(0))();
  RealColumn get stockValue => real().withDefault(const Constant(0))();
  IntColumn get qtySold => integer().withDefault(const Constant(0))();
  IntColumn get skuCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}
import 'package:drift/drift.dart';
import 'category_table.dart';

@DataClassName('ClosingBookData')
class ClosingBooks extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get periode => text()();
  TextColumn get periodeLabel => text().withDefault(const Constant(''))();
  RealColumn get omset => real().withDefault(const Constant(0))();
  RealColumn get hpp => real().withDefault(const Constant(0))();
  RealColumn get totalBeli => real().withDefault(const Constant(0))();
  RealColumn get biaya => real().withDefault(const Constant(0))();
  RealColumn get labaKotor => real().withDefault(const Constant(0))();
  RealColumn get labaBersih => real().withDefault(const Constant(0))();
  RealColumn get stockAkhir => real().withDefault(const Constant(0))();
  RealColumn get stockAwal => real().withDefault(const Constant(0))();
  RealColumn get piutangAkhir => real().withDefault(const Constant(0))();
  RealColumn get hutangAkhir => real().withDefault(const Constant(0))();
  RealColumn get modalAkhir => real().withDefault(const Constant(0))();
  TextColumn get categoryBreakdownJson => text().withDefault(const Constant('{}'))();
  TextColumn get topCategoryId => text().nullable()();
  TextColumn get worstCategoryId => text().nullable()();
  IntColumn get totalTransaksi => integer().withDefault(const Constant(0))();
  IntColumn get totalSkuTerjual => integer().withDefault(const Constant(0))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  TextColumn get lockedBy => text().nullable()();
  DateTimeColumn get lockedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

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
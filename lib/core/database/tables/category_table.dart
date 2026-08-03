import 'package:drift/drift.dart';

@DataClassName('CategoryData')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  TextColumn get slug => text().nullable()();
  TextColumn get type => text()(); // product, expense, customer, supplier

  TextColumn get description => text().nullable()();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get imageUrl => text().nullable()();

  TextColumn get parentId => text().nullable()();
  IntColumn get level => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get productCount => integer().withDefault(const Constant(0))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  TextColumn get status => text().withDefault(const Constant('aktif'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

abstract class CategoryType {
  static const String product = 'product';
  static const String expense = 'expense';
  static const String cashIn = 'cash_in';
  static const String customer = 'customer';
  static const String supplier = 'supplier';
  static const List<String> allTypes = [product, expense, cashIn, customer, supplier];
  static String getLabel(String type) {
    switch (type) {
      case product: return 'Perkakas';
      case expense: return 'Biaya';
      case customer: return 'Customer';
      case supplier: return 'Supplier';
      default: return 'Lainnya';
    }
  }
}

abstract class CategoryStatus {
  static const String aktif = 'aktif';
  static const String nonaktif = 'nonaktif';
}

abstract class CategorySort {
  static const String az = 'az';
  static const String za = 'za';
  static const String newest = 'newest';
  static const String mostUsed = 'mostUsed';
  static const String manual = 'manual';
}
import 'package:drift/drift.dart';

@DataClassName('UserData')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text().nullable()();
  TextColumn get name => text()();
  TextColumn get role => text()(); // owner, admin, kasir, salesman
  TextColumn get passwordHash => text().nullable()();
  TextColumn get pinCode => text().nullable()();
  TextColumn get apiKey => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get waNumber => text().nullable()(); // untuk Auto WA Struk
  TextColumn get salesArea => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))();
  BoolColumn get canOverridePrice => boolean().withDefault(const Constant(false))();
  BoolColumn get canGiveDiscount => boolean().withDefault(const Constant(false))();
  RealColumn get maxDiscountPercent => real().withDefault(const Constant(5.0))();
  BoolColumn get canCreateCustomer => boolean().withDefault(const Constant(true))();
  BoolColumn get canCollectPayment => boolean().withDefault(const Constant(true))();
  BoolColumn get canProcessReturn => boolean().withDefault(const Constant(false))();
  BoolColumn get canVoidTransaction => boolean().withDefault(const Constant(false))();
  BoolColumn get canManageStock => boolean().withDefault(const Constant(false))();
  // TAMBAHAN KEAMANAN X
  BoolColumn get canDeleteTransaction => boolean().withDefault(const Constant(false))();
  BoolColumn get canEditHpp => boolean().withDefault(const Constant(false))();
  BoolColumn get canViewProfit => boolean().withDefault(const Constant(false))();
  BoolColumn get canViewDashboardBos => boolean().withDefault(const Constant(false))();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('ShiftKasirData')
class ShiftKasir extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get initialCash => real().withDefault(const Constant(0.0))();
  RealColumn get totalCashSales => real().withDefault(const Constant(0.0))();
  RealColumn get totalNonCashSales => real().withDefault(const Constant(0.0))();
  RealColumn get totalReceivableCollected => real().withDefault(const Constant(0.0))();
  RealColumn get expectedCash => real().withDefault(const Constant(0.0))();
  RealColumn get actualCash => real().nullable()();
  RealColumn get cashDifference => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override Set<Column> get primaryKey => {id};
}

abstract class UserRole {
  static const String superuser = 'superuser';
  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String kasir = 'kasir';
  static const String salesman = 'salesman';
}
abstract class UserStatus {
  static const String aktif = 'aktif';
  static const String suspended = 'suspended';
}
abstract class ShiftStatus {
  static const String open = 'open';
  static const String closed = 'closed';
}
import 'package:drift/drift.dart';

@DataClassName('UserData')
class Users extends Table {
  // --- 1. IDENTITAS & OTENTIKASI ---
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get role => text()(); // 'superuser' / 'salesman' / 'admin'
  TextColumn get passwordHash => text().nullable()();
  TextColumn get apiKey => text().nullable()(); 

  // --- 2. DATA PROFIL & STATUS ---
  TextColumn get phone => text().nullable()();
  TextColumn get salesArea => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('aktif'))(); // 'aktif' / 'suspended'

  // --- 3. HAK AKSES HARGA & DISKON ---
  BoolColumn get canOverridePrice => boolean().withDefault(const Constant(false))(); // Melebur 'canEditPrice'
  BoolColumn get canGiveDiscount => boolean().withDefault(const Constant(false))();
  RealColumn get maxDiscountPercent => real().withDefault(const Constant(5.0))(); // Batas diskon (%)

  // --- 4. HAK AKSES OPERASIONAL & TRANSAKSI ---
  BoolColumn get canCreateCustomer => boolean().withDefault(const Constant(true))();
  BoolColumn get canCollectPayment => boolean().withDefault(const Constant(true))();
  BoolColumn get canProcessReturn => boolean().withDefault(const Constant(false))();
  BoolColumn get canVoidTransaction => boolean().withDefault(const Constant(false))(); // Melebur 'canDeleteTransaction'

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

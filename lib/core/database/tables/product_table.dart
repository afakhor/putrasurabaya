import 'package:drift/drift.dart';

@DataClassName('ProductData')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get shortName => text().withLength(max: 25).nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().withDefault(const Constant('Umum'))();
  TextColumn get subCategory => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get warehouseLocation => text().nullable()();
  TextColumn get tags => text().nullable()();
  RealColumn get buyPrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellPriceGeneral => real().withDefault(const Constant(0.0))();
  RealColumn get sellPriceTier1 => real().withDefault(const Constant(0.0))();
  RealColumn get sellPriceTier2 => real().withDefault(const Constant(0.0))();
  RealColumn get sellPriceTier3 => real().withDefault(const Constant(0.0))();
  RealColumn get maxDiscountSales => real().withDefault(const Constant(0.0))();
  BoolColumn get isPriceLocked => boolean().withDefault(const Constant(true))();
  RealColumn get stock => real().withDefault(const Constant(0.0))();
  RealColumn get minStock => real().withDefault(const Constant(5.0))();
  RealColumn get maxStock => real().withDefault(const Constant(100.0))();
  BoolColumn get allowMinusStock => boolean().withDefault(const Constant(false))();
  RealColumn get weight => real().withDefault(const Constant(0.0))();
  TextColumn get dimensions => text().nullable()();
  RealColumn get ppnPercent => real().withDefault(const Constant(0.0))();
  IntColumn get rewardPoints => integer().withDefault(const Constant(0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get statusActive => text().withDefault(const Constant('aktif'))();

  @override 
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductAssetData')
class ProductAssets extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get imagePath => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override 
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductUnitData')
class ProductUnits extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)(); 
  TextColumn get unitName => text()();
  IntColumn get conversion => integer()();
  RealColumn get buyPriceUnit => real()(); 
  RealColumn get sellPriceUnit => real()();
  TextColumn get barcode => text().nullable()();

  @override 
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductVariantData')
class ProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get skuVariant => text()();
  TextColumn get variantName => text()();
  TextColumn get barcode => text().nullable()();
  RealColumn get stock => real().withDefault(const Constant(0.0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0.0))();

  @override 
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductPromoData')
class ProductPromos extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get discountNominal => real().withDefault(const Constant(0.0))();
  TextColumn get promoType => text().withDefault(const Constant('regular'))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();

  @override 
  Set<Column> get primaryKey => {id};
}

@DataClassName('StockMutationData')
class StockMutations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId => text().nullable()();
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  RealColumn get hppSnapshot => real()();
  RealColumn get currentStockSnapshot => real()();
  TextColumn get referenceNo => text()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();

  @override 
  Set<Column> get primaryKey => {id};
}

class Product {
  final String id;
  final String name;
  final String? barcode;
  final double sellPrice;
  final double buyPrice;
  final String unitBase;
  final int stock;
  final String category;

  Product({
    required this.id, required this.name, this.barcode,
    required this.sellPrice, required this.buyPrice,
    this.unitBase = 'pcs', this.stock = 0, this.category = 'Umum',
  });

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id, name: data['name']?? '',
      barcode: data['barcode'],
      sellPrice: (data['sellPrice']?? data['sellPriceGeneral']?? 0).toDouble(),
      buyPrice: (data['buyPrice']?? 0).toDouble(),
      unitBase: data['unitBase']?? 'pcs',
      stock: (data['stock']?? 0).toInt(),
      category: data['category']?? data['categoryId']?? 'Umum',
    );
  }

  // Untuk konversi dari Drift ProductData ke Model POS biar offline tetap jalan
  factory Product.fromDrift(dynamic p) {
    return Product(
      id: p.id, name: p.name, barcode: p.barcode,
      sellPrice: p.sellPriceGeneral, buyPrice: p.buyPrice,
      unitBase: 'pcs', stock: p.stock.toInt(), category: p.categoryId,
    );
  }
}

class CartItem {
  final Product product;
  final double qty;
  final String unit;
  final double price;
  CartItem({required this.product, this.qty = 1, required this.unit, required this.price});
  double get subtotal => qty * price;
  CartItem copyWith({double? qty, String? unit, double? price}) {
    return CartItem(product: product, qty: qty?? this.qty, unit: unit?? this.unit, price: price?? this.price);
  }
}
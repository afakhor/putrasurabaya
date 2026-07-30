import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/customer_table.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomerDao extends DatabaseAccessor<LocalDatabase> with _$CustomerDaoMixin {
  CustomerDao(LocalDatabase db) : super(db);

  // ===========================================================================
  // 1. READ OPERATIONS
  // ===========================================================================

  /// Ambil data customer berdasarkan ID (Sangat penting untuk fitur 3-Play WA)
  Future<CustomerData?> getCustomerById(String customerId) {
    return (select(customers)..where((c) => c.id.equals(customerId))).getSingleOrNull();
  }

  /// Ambil daftar semua customer aktif (untuk list di UI)
  Stream<List<CustomerData>> watchAllCustomers() {
    return (select(customers)
          ..where((c) => c.status.equals('aktif'))
          ..orderBy([(c) => OrderingTerm(expression: c.name)]))
        .watch();
  }

  // ===========================================================================
  // 2. WRITE OPERATIONS
  // ===========================================================================

  /// Tambah customer baru
  Future<String> createCustomer({
    required String name,
    String? phone,
    String? address,
    String? salesArea,
    String? categoryId,
    double creditLimit = 0.0,
  }) async {
    final newId = 'CUST-${DateTime.now().microsecondsSinceEpoch}';
    
    await into(customers).insert(
      CustomersCompanion.insert(
        id: newId,
        name: name,
        phone: Value(phone),
        address: Value(address),
        salesArea: Value(salesArea),
        categoryId: Value(categoryId),
        creditLimit: Value(creditLimit),
        status: const Value('aktif'),
        isSynced: const Value(false),
      ),
    );
    return newId;
  }

  /// Update data customer
  Future<void> updateCustomer(CustomerData customer) async {
    await update(customers).replace(customer.copyWith(updatedAt: DateTime.now(), isSynced: false));
  }

  /// Update saldo piutang (Sangat krusial untuk fitur penagihan)
  Future<void> updateCustomerDebt(String customerId, double newDebt) async {
    await (update(customers)..where((c) => c.id.equals(customerId))).write(
      CustomersCompanion(
        totalDebt: Value(newDebt),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  /// Soft delete customer
  Future<void> setCustomerStatus(String customerId, String status) async {
    await (update(customers)..where((c) => c.id.equals(customerId))).write(
      CustomersCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }
}

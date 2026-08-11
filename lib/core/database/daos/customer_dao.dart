import 'package:drift/drift.dart';
import 'package:ud_putra_kasir/core/database/local_database.dart';
import 'package:ud_putra_kasir/core/database/tables/customer_table.dart';
part 'customer_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomerDao extends DatabaseAccessor<LocalDatabase> with _$CustomerDaoMixin {
  CustomerDao(LocalDatabase db) : super(db);
  Future<CustomerData?> getCustomerById(String id) => (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();
  Stream<List<CustomerData>> watchAllCustomers() {
    return (select(customers)..where((c) => c.status.equals('aktif'))..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }
  Stream<List<CustomerData>> watchBlacklisted() {
    return (select(customers)..where((c) => c.blacklistReason.isNotNull())..orderBy([(c) => OrderingTerm.desc(c.blacklistAt)])).watch();
  }
  Stream<List<CustomerData>> searchCustomer(String q) {
    if(q.isEmpty) return watchAllCustomers();
    return (select(customers)..where((c) => c.name.like('%$q%') | c.wa.like('%$q%') | c.phone.like('%$q%'))).watch();
  }
  Future<String> createCustomerFull({required String name, String? phone, String? wa, String? address, String? kota, String kelas = 'Retail', String paymentType = 'Tunai', String tierHarga = 'Umum'}) async {
    final id = 'CUS-${DateTime.now().millisecondsSinceEpoch}';
    await into(customers).insert(CustomersCompanion.insert(
      id: id, code: Value('CUS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'), name: name,
      phone: Value(phone), wa: Value(wa), address: Value(address), kota: Value(kota),
      kelas: Value(kelas), paymentType: Value(paymentType), tierHarga: Value(tierHarga),
      status: const Value('aktif'), isSynced: const Value(false),
    ));
    return id;
  }
  Future<void> updateCustomerDebt(String id, double sisa) => (update(customers)..where((c)=> c.id.equals(id))).write(CustomersCompanion(sisaHutang: Value(sisa), updatedAt: Value(DateTime.now()), isSynced: const Value(false)));
  Future<void> setStatus(String id, String status) => (update(customers)..where((c)=> c.id.equals(id))).write(CustomersCompanion(status: Value(status), updatedAt: Value(DateTime.now())));
  Future<void> blacklistCustomer({required String id, required String reason, required String ownerId}) async {
    await (update(customers)..where((c)=> c.id.equals(id))).write(CustomersCompanion(blacklistReason: Value(reason), blacklistBy: Value(ownerId), blacklistAt: Value(DateTime.now()), status: const Value('nonaktif'), updatedAt: Value(DateTime.now())));
  }
  Future<void> unblacklistCustomer(String id) async {
    await (update(customers)..where((c)=> c.id.equals(id))).write(CustomersCompanion(blacklistReason: const Value.absent(), blacklistBy: const Value.absent(), blacklistAt: const Value.absent(), status: const Value('aktif'), updatedAt: Value(DateTime.now())));
  }
}
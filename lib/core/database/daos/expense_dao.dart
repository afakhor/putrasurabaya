import 'package:drift/drift.dart';
import '../local_database.dart';
import '../tables/finance_table.dart';
part 'expense_dao.g.dart';
@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<LocalDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);
  Future<List<ExpenseData>> getAll() => select(expenses).get();
}
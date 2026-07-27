import 'package:drift/drift.dart';

import '../local_database.dart';
import '../constant/constant_debt_status.dart';

extension DebtExtension on LocalDatabase {

  /// 1. Pembayaran Cicilan / Pelunasan Piutang dari Customer
  Future<void> bayarAngsuranPiutang({
    required String receivableId,
    required double jumlahBayar,
    required String paymentMethod,
    String? catatan,
  }) async {
    await transaction(() async {
      // 1. Ambil Data Piutang Saat Ini
      final item = await (select(receivables)
            ..where((tbl) => tbl.id.equals(receivableId)))
          .getSingle();

      final newPaid = item.paidAmount + jumlahBayar;
      final newRemaining = item.totalAmount - newPaid;

      final newStatus = DebtStatus.tentukanStatus(newRemaining, jumlahBayar);

      // 2. Update Status Piutang
      await (update(receivables)..where((tbl) => tbl.id.equals(receivableId))).write(
        ReceivablesCompanion(
          paidAmount: Value(newPaid),
          remainingAmount: Value(newRemaining < 0 ? 0.0 : newRemaining),
          status: Value(newStatus),
        ),
      );

      // 3. Catat Riwayat Pembayaran
      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          id: 'PAY-AR-${DateTime.now().millisecondsSinceEpoch}',
          refId: receivableId,
          type: 'receivable_collect',
          amount: jumlahBayar,
          paymentMethod: paymentMethod,
          notes: Value(catatan ??
              (newStatus == DebtStatus.paid
                  ? 'Pelunasan Piutang Pelanggan'
                  : 'Cicilan Piutang Pelanggan')),
        ),
      );
    });
  }

  /// 2. Pencatatan Hutang Usaha (Pembelian Barang Tempo ke Supplier)
  Future<void> catatPembelianTempo({
    required String purchaseRef,
    required String supplierId,
    required double totalAmount,
    required double dpAmount,
    required DateTime dueDate,
  }) async {
    final sisaHutang = totalAmount - dpAmount;
    final status = DebtStatus.tentukanStatus(sisaHutang, dpAmount);

    await into(payables).insert(
      PayablesCompanion.insert(
        id: 'AP-${DateTime.now().millisecondsSinceEpoch}',
        purchaseRef: purchaseRef,
        supplierId: supplierId,
        totalAmount: totalAmount,
        paidAmount: Value(dpAmount),
        remainingAmount: sisaHutang < 0 ? 0.0 : sisaHutang,
        dueDate: dueDate,
        status: Value(status),
      ),
    );
  }
}

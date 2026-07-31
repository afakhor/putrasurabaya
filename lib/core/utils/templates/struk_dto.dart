// struk_dto.dart

// 1. DTO untuk Barang (Dipakai di POS dan Faktur)
class ReceiptItemDTO {
  final String productName;
  final double quantity;
  final double subtotal;

  ReceiptItemDTO({
    required this.productName, 
    required this.quantity, 
    required this.subtotal
  });
}

// 2. DTO untuk POS
class PosReceiptDTO {
  final String invoiceId;          
  final DateTime transactionDate; 
  final List<ReceiptItemDTO> items;
  final double total;
  final double paidAmount;
  final double change;
  final double debt;
  final String paymentMethod;

  PosReceiptDTO({
    required this.invoiceId,
    required this.transactionDate,
    required this.items,
    required this.total,
    required this.paidAmount,
    required this.change,
    required this.debt,
    required this.paymentMethod,
  });
}


// 3. DTO untuk Faktur (Unpaid)
// struk_dto.dart

class FakturDTO {
  final String invoiceId;
  final String customerName;
  final DateTime date;
  final DateTime dueDate;
  final List<ReceiptItemDTO> items;
  final double total;
  final double paidAmount; // DP / Uang Muka (jika ada)

  FakturDTO({
    required this.invoiceId,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.total,
    this.paidAmount = 0,
  });

  double get remainingDebt => (total - paidAmount).clamp(0, double.infinity);
}

// 4. DTO untuk Penagihan (Titip/Cicilan)
// struk_dto.dart

class PaymentHistoryDTO {
  final DateTime date;
  final double amount;

  PaymentHistoryDTO({
    required this.date, 
    required this.amount,
  });
}

class PenagihanDTO {
  final String invoiceId;
  final String customerName;       // Tambahan: Nama Pelanggan
  final DateTime paymentDate;      // Tambahan: Waktu Bayar
  final double totalDebt;          // Total piutang awal
  final double currentPayment;     // Bayar saat ini
  final double remainingDebt;      // Sisa piutang
  final List<PaymentHistoryDTO> history;

  PenagihanDTO({
    required this.invoiceId,
    required this.customerName,
    required this.paymentDate,
    required this.totalDebt,
    required this.currentPayment,
    required this.remainingDebt,
    this.history = const [],
  });
}

class PenagihanLunasDTO {
  final String invoiceId;
  final String customerName;
  final DateTime paymentDate;
  final double totalPaid;

  PenagihanLunasDTO({
    required this.invoiceId,
    required this.customerName,
    required this.paymentDate,
    required this.totalPaid,
  });
}

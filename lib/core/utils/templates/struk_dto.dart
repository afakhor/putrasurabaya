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
class FakturDTO {
  final String invoiceId;
  final String customerName;
  final DateTime date;
  final DateTime dueDate;
  final List<ReceiptItemDTO> items;
  final double total;

  FakturDTO({
    required this.invoiceId,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.total,
  });
}

// 4. DTO untuk Penagihan (Titip/Cicilan)
class PaymentHistoryDTO {
  final DateTime date;
  final double amount;
  PaymentHistoryDTO({required this.date, required this.amount});
}

class PenagihanDTO {
  final String invoiceId;
  final double totalDebt;
  final double currentPayment;
  final double remainingDebt;
  final List<PaymentHistoryDTO> history;

  PenagihanDTO({
    required this.invoiceId,
    required this.totalDebt,
    required this.currentPayment,
    required this.remainingDebt,
    this.history = const [],
  });
}

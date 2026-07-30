// DataTransferObject

// 1. DTO untuk Barang (Dipakai di POS, Faktur, Penagihan)
class ReceiptItemDTO {
  final String productName;
  final double quantity;
  final double subtotal;
  ReceiptItemDTO({required this.productName, required this.quantity, required this.subtotal});
}

// 2. DTO Khusus Penagihan (Sistem Titip)
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
    this.history = const []
  });
}

class PaymentHistoryDTO {
  final String date;
  final double amount;
  PaymentHistoryDTO({required this.date, required this.amount});
}

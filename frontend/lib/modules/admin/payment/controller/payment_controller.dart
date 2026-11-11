import '../model/payment_model.dart';

class PaymentController {
  // ฟังก์ชันกรองรายการธุรกรรมตามหมวดหมู่ (Tab Filter)
  List<PaymentTransaction> filterTransactions(
    List<PaymentTransaction> transactions,
    String filter,
  ) {
    return transactions.where((tx) {
      if (filter == 'Pending Refund') {
        return tx.isPending;
      } else if (filter == 'Collected') {
        return tx.isIncome && !tx.isPending;
      } else if (filter == 'Refunded') {
        return !tx.isIncome;
      }
      return true; // กรณี 'All'
    }).toList();
  }

  // ฟังก์ชันตรวจสอบความถูกต้องของยอดเงิน
  bool validateAmount(double amount) {
    return amount > 0;
  }
}

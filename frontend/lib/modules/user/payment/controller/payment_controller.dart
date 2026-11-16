import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';

class PaymentResult {
  final int borrowId;
  final int? walletBalance;

  const PaymentResult({required this.borrowId, this.walletBalance});
}

class PaymentController extends ChangeNotifier {
  PaymentController({this.walletBalance = 0, List<BorrowModel>? borrows})
    : _borrows = borrows ?? <BorrowModel>[];

  final List<BorrowModel> _borrows;
  int walletBalance;
  bool loading = false;
  bool paying = false;
  String? error;

  Future<void> loadWallet() async {
    loading = true;
    error = null;
    notifyListeners();
    loading = false;
    notifyListeners();
  }

  bool canPay(num total) => total >= 0 && walletBalance >= total;

  Future<PaymentResult?> confirmPayment({
    required int borrowId,
    required num total,
  }) async {
    final index = _borrows.indexWhere((item) => item.id == borrowId);
    if (index == -1) {
      error = 'Borrow not found';
      notifyListeners();
      return null;
    }
    final borrow = _borrows[index];

    if (total < 0) {
      error = 'Invalid payment amount';
      notifyListeners();
      return null;
    }

    if (!canPay(total)) {
      error = 'Insufficient wallet balance';
      notifyListeners();
      return null;
    }

    if (borrow.paymentStatus == 'paid') {
      error = 'Borrow is already paid';
      notifyListeners();
      return null;
    }

    paying = true;
    error = null;
    notifyListeners();

    walletBalance -= total.ceil();
    _borrows[index] = borrow.copyWith(
      status: 'borrowed',
      paymentStatus: 'paid',
    );
    paying = false;
    notifyListeners();
    return PaymentResult(borrowId: borrowId, walletBalance: walletBalance);
  }
}

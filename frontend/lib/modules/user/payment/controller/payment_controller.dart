import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/payment/service/payment_api_service.dart';

class PaymentResult {
  final int borrowId;
  final num? walletBalance;

  const PaymentResult({required this.borrowId, this.walletBalance});
}

class PaymentController extends ChangeNotifier {
  PaymentController({
    this.walletBalance = 0,
    List<BorrowModel>? borrows,
    this.apiService,
  }) : _borrows = borrows ?? <BorrowModel>[];

  final List<BorrowModel> _borrows;
  final PaymentApiService? apiService;
  num walletBalance;
  BorrowModel? borrow;
  bool loading = false;
  bool paying = false;
  String? error;
  String? loadError;
  bool _disposed = false;

  Future<void> loadWallet() async {
    if (_disposed) return;
    loading = true;
    error = null;
    loadError = null;
    notifyListeners();
    try {
      final service = apiService;
      if (service != null) {
        walletBalance = await service.fetchWalletBalance();
      }
    } on Exception catch (exception) {
      if (!_disposed) loadError = exception.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadPayment(int? borrowId) async {
    if (_disposed) return;
    if (borrowId == null) {
      loadError = 'Missing borrow request';
      notifyListeners();
      return;
    }

    final service = apiService;
    if (service == null) {
      borrow = null;
      error = null;
      loadError = null;
      for (final item in _borrows) {
        if (item.id == borrowId) {
          borrow = item;
          break;
        }
      }
      if (borrow == null) loadError = 'Borrow not found';
      if (!_disposed) notifyListeners();
      return;
    }

    loading = true;
    error = null;
    loadError = null;
    borrow = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        service.fetchWalletBalance(),
        service.fetchBorrow(borrowId),
      ]);
      final walletResult = results[0];
      final borrowResult = results[1];
      if (walletResult is! num || borrowResult is! BorrowModel) {
        throw const FormatException('Invalid payment details response');
      }
      if (_disposed) return;
      walletBalance = walletResult;
      borrow = borrowResult;
    } on Exception catch (exception) {
      if (!_disposed) loadError = exception.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  bool canPay(num total) => total >= 0 && walletBalance >= total;

  Future<PaymentResult?> confirmPayment({
    required int borrowId,
    required num total,
  }) async {
    if (_disposed || paying) return null;
    final service = apiService;
    if (service != null) {
      final currentBorrow = borrow;
      if (currentBorrow == null || currentBorrow.id != borrowId) {
        error = 'Borrow not found';
        notifyListeners();
        return null;
      }
      final amountDue = currentBorrow.totalAmount ?? total;
      if (amountDue < 0) {
        error = 'Invalid payment amount';
        notifyListeners();
        return null;
      }
      if (!canPay(amountDue)) {
        error = 'Insufficient wallet balance';
        notifyListeners();
        return null;
      }
      if (currentBorrow.paymentStatus == 'paid') {
        error = 'Borrow is already paid';
        notifyListeners();
        return null;
      }

      paying = true;
      error = null;
      notifyListeners();
      try {
        final result = await service.pay(borrowId);
        if (_disposed) return null;
        walletBalance = result.walletBalance;
        borrow = currentBorrow.copyWith(
          status: result.status,
          paymentStatus: result.paymentStatus,
        );
        return PaymentResult(
          borrowId: result.borrowId,
          walletBalance: result.walletBalance,
        );
      } on Exception catch (exception) {
        if (!_disposed) error = exception.toString();
        return null;
      } finally {
        paying = false;
        if (!_disposed) notifyListeners();
      }
    }

    final index = _borrows.indexWhere((item) => item.id == borrowId);
    if (index == -1) {
      error = 'Borrow not found';
      notifyListeners();
      return null;
    }
    final localBorrow = _borrows[index];

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

    if (localBorrow.paymentStatus == 'paid') {
      error = 'Borrow is already paid';
      notifyListeners();
      return null;
    }

    paying = true;
    error = null;
    notifyListeners();

    walletBalance -= total;
    _borrows[index] = localBorrow.copyWith(
      status: 'borrowed',
      paymentStatus: 'paid',
    );
    paying = false;
    notifyListeners();
    return PaymentResult(borrowId: borrowId, walletBalance: walletBalance);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

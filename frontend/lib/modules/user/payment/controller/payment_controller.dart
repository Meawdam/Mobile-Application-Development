import 'package:flutter/foundation.dart';

import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/borrow_api.dart';
import 'package:frontend/services/wallet_api.dart';

class PaymentResult {
  final int borrowId;
  final int? walletBalance;

  const PaymentResult({required this.borrowId, this.walletBalance});
}

class PaymentController extends ChangeNotifier {
  PaymentController({
    WalletApi? walletApi,
    BorrowApi? borrowApi,
  })  : _walletApi = walletApi ?? WalletApi(),
        _borrowApi = borrowApi ?? BorrowApi();

  final WalletApi _walletApi;
  final BorrowApi _borrowApi;

  int walletBalance = 0;
  bool loading = false;
  bool paying = false;
  String? error;

  Future<void> loadWallet() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final wallet = await _walletApi.getWallet();
      walletBalance = wallet.balance;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Unable to load wallet balance';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool canPay(num total) => walletBalance >= total;

  Future<PaymentResult?> confirmPayment({
    required int borrowId,
    required num total,
  }) async {
    if (!canPay(total)) {
      error = 'Insufficient wallet balance';
      notifyListeners();
      return null;
    }

    paying = true;
    error = null;
    notifyListeners();

    try {
      final paid = await _borrowApi.pay(borrowId);
      if (paid.walletBalance != null) {
        walletBalance = paid.walletBalance!;
      } else {
        await loadWallet();
      }
      return PaymentResult(
        borrowId: borrowId,
        walletBalance: walletBalance,
      );
    } on ApiException catch (e) {
      error = e.message;
      await loadWallet();
      return null;
    } catch (_) {
      error = 'Unable to complete payment';
      return null;
    } finally {
      paying = false;
      notifyListeners();
    }
  }
}

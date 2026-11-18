import 'package:flutter/foundation.dart';
import 'package:frontend/modules/user/wallet/service/wallet_api_service.dart';

class WalletController extends ChangeNotifier {
  WalletController({num initialBalance = 0, this.apiService})
    : balance = initialBalance;

  final WalletApiService? apiService;
  num balance;
  bool loading = false;
  bool submitting = false;
  String? error;
  String? loadError;
  bool _disposed = false;
  int _balanceRevision = 0;

  Future<void> load() async {
    if (_disposed) return;
    final service = apiService;
    if (service == null) return;

    final revision = _balanceRevision;
    loading = true;
    error = null;
    loadError = null;
    notifyListeners();
    try {
      final wallet = await service.fetchWallet();
      if (!_disposed && revision == _balanceRevision) {
        balance = wallet.balance;
      }
    } on Exception catch (exception) {
      if (!_disposed) loadError = exception.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  bool topUp(int amount) {
    if (_disposed) return false;
    if (amount <= 0) {
      error = 'Enter a positive amount';
      notifyListeners();
      return false;
    }

    balance += amount;
    _balanceRevision++;
    error = null;
    notifyListeners();
    return true;
  }

  Future<bool> topUpOnline(num amount) async {
    if (_disposed || submitting) return false;
    if (amount <= 0) {
      error = 'Enter a positive amount';
      notifyListeners();
      return false;
    }
    final service = apiService;
    if (service == null) {
      error = 'Wallet service is unavailable';
      notifyListeners();
      return false;
    }

    submitting = true;
    error = null;
    notifyListeners();
    try {
      final wallet = await service.topUp(amount);
      if (_disposed) return false;
      _balanceRevision++;
      balance = wallet.balance;
      loadError = null;
      return true;
    } on Exception catch (exception) {
      if (!_disposed) error = exception.toString();
      return false;
    } finally {
      submitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

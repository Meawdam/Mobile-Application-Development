import 'package:flutter/foundation.dart';

import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/wallet_api.dart';

class WalletController extends ChangeNotifier {
  WalletController({WalletApi? walletApi})
      : _walletApi = walletApi ?? WalletApi();

  final WalletApi _walletApi;

  int balance = 0;
  bool loading = false;
  bool submitting = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final wallet = await _walletApi.getWallet();
      balance = wallet.balance;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Unable to load wallet';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> topUp(int amount) async {
    if (amount <= 0) {
      return false;
    }

    submitting = true;
    error = null;
    notifyListeners();
    try {
      final wallet = await _walletApi.topUp(amount);
      balance = wallet.balance;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Unable to top up wallet';
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}

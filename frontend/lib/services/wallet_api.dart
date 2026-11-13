import 'package:frontend/model/wallet/wallet_model.dart';

import 'api_client.dart';

class WalletApi {
  WalletApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<WalletModel> getWallet() async {
    final response = await _client.get('/api/wallet');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid wallet response from server');
    }
    return WalletModel.fromJson(data);
  }

  Future<WalletModel> topUp(int amount) async {
    final response = await _client.post(
      '/api/wallet/top-up',
      body: {'amount': amount},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid top-up response from server');
    }
    return WalletModel.fromJson(data);
  }
}

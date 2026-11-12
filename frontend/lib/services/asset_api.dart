import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:frontend/model/asset/asset_model.dart';

import 'api_client.dart';

/// Asset endpoints under `/api/assets` (see `backend/module/asset`).
class AssetApi {
  AssetApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<AssetModel>> getAvailableAssets({String? query}) async {
    final response = await _client.get(
      '/api/assets',
      query: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );

    final data = response['data'];
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(AssetModel.fromJson)
        .toList();
  }

  Future<List<AssetModel>> getMyAssets() async {
    final response = await _client.get('/api/assets/mine');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AssetModel.fromJson)
        .toList();
  }

  Future<AssetModel> getAssetById(int id) async {
    final response = await _client.get('/api/assets/$id');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid asset response from server');
    }
    return AssetModel.fromJson(data);
  }

  Future<AssetModel> createAsset({
    required String name,
    required String description,
    required String downPayment,
    required String price,
    required String pickupPoint,
    required String returnBefore,
    required Uint8List imageBytes,
    required String imageFilename,
  }) async {
    final response = await _client.postMultipart(
      '/api/assets',
      fields: {
        'name': name,
        'description': description,
        'down_payment': downPayment,
        'price': price,
        'pickup_point': pickupPoint,
        'return_before': returnBefore,
      },
      files: [
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFilename,
        ),
      ],
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid create-asset response from server');
    }
    return AssetModel.fromJson(data);
  }

  Future<AssetModel> updateAsset({
    required int id,
    required String name,
    required String description,
    required String downPayment,
    required String price,
    required String pickupPoint,
    required String returnBefore,
  }) async {
    final response = await _client.patch(
      '/api/assets/$id',
      body: {
        'name': name,
        'description': description,
        'down_payment': downPayment,
        'price': price,
        'pickup_point': pickupPoint,
        'return_before': returnBefore,
      },
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Invalid update-asset response from server');
    }
    return AssetModel.fromJson({...data, 'id': data['id'] ?? id});
  }

  Future<void> deleteAsset(int id) async {
    await _client.delete('/api/assets/$id');
  }
}

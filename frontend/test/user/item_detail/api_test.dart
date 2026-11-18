import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/item_detail/service/item_detail_api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'loads asset details with authorization and resolves image URLs',
    () async {
      final service = ItemDetailApiService(
        baseUrl: 'https://example.test',
        authService: _TestAuthService(),
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/assets/9');
          expect(request.headers['Authorization'], 'Bearer test-token');
          return http.Response(
            jsonEncode({
              'data': {
                'id': 9,
                'owner_id': 2,
                'owner_username': 'Morgan',
                'image': '/uploads/lens.png',
                'name': 'Prime lens',
                'description': 'A sharp camera lens.',
                'status': 'ready',
                'approval': 'approved',
                'down_payment': 50.5,
                'return_before': '2030-01-01',
                'price': 12,
                'pickup_point': 'Library',
              },
            }),
            200,
          );
        }),
      );

      final asset = await service.fetchAsset(9);

      expect(asset.id, 9);
      expect(asset.name, 'Prime lens');
      expect(asset.imageUrl, 'https://example.test/uploads/lens.png');
      expect(asset.downPayment, 50.5);
      service.dispose();
    },
  );

  test('surfaces item detail API errors', () async {
    final service = ItemDetailApiService(
      authService: _TestAuthService(),
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'message': 'Item not found'}), 404),
      ),
    );

    await expectLater(
      service.fetchAsset(999),
      throwsA(
        isA<ItemDetailApiException>().having(
          (error) => error.message,
          'message',
          'Item not found',
        ),
      ),
    );
    service.dispose();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}

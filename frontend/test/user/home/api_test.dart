import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/home/service/home_api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads available assets with search and bearer token', () async {
    final service = HomeApiService(
      baseUrl: 'https://example.test',
      authService: _TestAuthService(),
      client: MockClient((request) async {
        expect(request.url.path, '/api/assets');
        expect(request.url.queryParameters['q'], 'camera');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 12,
                'owner_id': 3,
                'owner_username': 'Alex',
                'image': '/uploads/camera.png',
                'name': 'Camera',
                'description': 'Digital camera',
                'status': 'ready',
                'approval': 'approved',
                'down_payment': 0,
                'return_before': '2030-01-01',
                'price': 50,
                'pickup_point': 'Library',
              },
            ],
          }),
          200,
        );
      }),
    );

    final assets = await service.fetchAvailableAssets(query: ' camera ');

    expect(assets.single.name, 'Camera');
    expect(assets.single.imageUrl, 'https://example.test/uploads/camera.png');
    service.dispose();
  });

  test('surfaces an API error message', () async {
    final service = HomeApiService(
      authService: _TestAuthService(),
      client: MockClient(
        (_) async => http.Response(jsonEncode({'message': 'Unavailable'}), 503),
      ),
    );

    await expectLater(
      service.fetchAvailableAssets(),
      throwsA(
        isA<HomeApiException>().having(
          (error) => error.message,
          'message',
          'Unavailable',
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

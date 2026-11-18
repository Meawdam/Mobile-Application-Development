import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/home/controller/home_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'initialize loads approved available items and supports search',
    () async {
      final controller = HomeController(
        availableItems: const [
          AssetModel(
            id: 1,
            ownerId: 2,
            name: 'Camera',
            description: 'Digital camera',
            status: 'available',
            approval: 'approved',
            downPayment: 0,
            returnBefore: '2030-01-01',
            price: 50,
            pickupPoint: 'Canteen',
          ),
          AssetModel(
            id: 2,
            ownerId: 2,
            name: 'Lens',
            description: 'Camera lens',
            status: 'available',
            approval: 'pending',
            downPayment: 0,
            returnBefore: '2030-01-01',
            price: 30,
            pickupPoint: 'Canteen',
          ),
          AssetModel(
            id: 3,
            ownerId: 2,
            name: 'Tripod',
            description: 'Support stand',
            status: 'borrowed',
            approval: 'approved',
            downPayment: 0,
            returnBefore: '2030-01-01',
            price: 20,
            pickupPoint: 'Canteen',
          ),
        ],
      );

      await controller.initialize();

      expect(controller.user?.username, '');
      expect(controller.items.map((item) => item.name), ['Camera']);

      await controller.search('digital');

      expect(controller.query, 'digital');
      expect(controller.items.map((item) => item.name), ['Camera']);
      controller.dispose();
    },
  );

  test('controller loads and searches assets through the backend', () async {
    final queries = <String?>[];
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-token');
      queries.add(request.url.queryParameters['q']);
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 12,
              'owner_id': 3,
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
    });
    final controller = HomeController(
      client: client,
      authService: _TestAuthService(),
      baseUrl: 'https://example.test',
    );

    await controller.initialize();
    expect(controller.items.single.name, 'Camera');
    await controller.search('digital');

    expect(queries, [null, 'digital']);
    expect(controller.query, 'digital');
    expect(controller.items.single.id, 12);
    controller.dispose();
    client.close();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}

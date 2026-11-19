import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/item_detail/controller/item_detail_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('load reads item details from the provided list', () async {
    final controller = ItemDetailController(
      items: [
        const AssetModel(
          id: 9,
          ownerId: 1,
          name: 'Lens',
          description: 'Camera lens',
          status: 'available',
          approval: 'approved',
          downPayment: 0,
          returnBefore: '2030-01-01',
          price: 100,
          pickupPoint: 'Canteen',
        ),
      ],
    );

    await controller.load(9);

    expect(controller.asset?.id, 9);
    expect(controller.asset?.name, 'Lens');
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    controller.dispose();
  });

  test('load reports a missing item and clears the asset', () async {
    final controller = ItemDetailController(items: const []);

    await controller.load(1);

    expect(controller.asset, isNull);
    expect(controller.error, 'Item not found');
    controller.dispose();
  });

  test('controller loads item details through the backend', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/assets/9');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        jsonEncode({
          'data': {
            'id': 9,
            'owner_id': 1,
            'name': 'Lens',
            'description': 'Camera lens',
            'status': 'ready',
            'approval': 'approved',
            'down_payment': 10.5,
            'return_before': '2030-01-01',
            'price': 100,
            'pickup_point': 'Canteen',
          },
        }),
        200,
      );
    });
    final controller = ItemDetailController(
      client: client,
      authService: _TestAuthService(),
      baseUrl: 'https://example.test',
    );

    await controller.load(9);

    expect(controller.asset?.name, 'Lens');
    expect(controller.asset?.downPayment, 10.5);
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    controller.dispose();
    client.close();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/edit_item/controller/edit_item_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

EditItemController makeController(
  MockClient client, {
  FakeAuthservice? auth,
}) {
  return EditItemController(
    client: client,
    authService: auth ?? FakeAuthservice(),
  );
}

void main() {
  test('load calls GET /api/assets/:id and fills the asset', () async {
    late http.Request captured;
    final controller = makeController(
      MockClient((request) async {
        captured = request;
        return jsonResponse({'data': assetJson(id: 1)});
      }),
    );

    await controller.load(1);

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/assets/1');
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(controller.asset?.name, 'My camera');
    expect(controller.asset?.price, 120);
    expect(controller.lendingEndDate, DateTime(2030, 1, 1));
    expect(controller.error, isNull);
    expect(controller.loading, isFalse);
  });

  test('load shows the backend message when the item is not found', () async {
    final controller = makeController(
      MockClient((request) async => jsonResponse({'message': 'Asset not found'}, 404)),
    );

    await controller.load(99);

    expect(controller.asset, isNull);
    expect(controller.error, 'Asset not found');
  });

  test('save sends PATCH /api/assets/:id with the edited values', () async {
    late http.Request captured;
    final controller = makeController(
      MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse({'data': assetJson(id: 1)});
        }
        captured = request;
        return jsonResponse({'message': 'Asset updated successfully'});
      }),
    );
    await controller.load(1);

    final result = await controller.save(
      name: 'New camera',
      description: 'Updated',
      price: '150',
      deposit: '700',
      pickupPoint: 'Library',
    );

    expect(result, EditItemResult.success);
    expect(captured.method, 'PATCH');
    expect(captured.url.path, '/api/assets/1');
    expect(captured.headers['Authorization'], 'Bearer test-token');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['name'], 'New camera');
    expect(body['description'], 'Updated');
    expect(body['price'], 150);
    expect(body['down_payment'], 700);
    expect(body['pickup_point'], 'Library');
    expect(body['return_before'], '2030-01-01');
    expect(controller.asset?.name, 'New camera');
    expect(controller.asset?.pickupPoint, 'Library');
  });

  test('save shows the backend message when the item is borrowed', () async {
    final controller = makeController(
      MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse({'data': assetJson(id: 1)});
        }
        return jsonResponse(
          {'message': 'Cannot edit an asset that is currently borrowed'},
          400,
        );
      }),
    );
    await controller.load(1);

    final result = await controller.save(
      name: 'New camera',
      description: 'Updated',
      price: '150',
      deposit: '700',
      pickupPoint: 'Library',
    );

    expect(result, EditItemResult.failed);
    expect(controller.error, 'Cannot edit an asset that is currently borrowed');
    expect(controller.asset?.name, 'My camera');
  });

  test('save validates input without calling the API', () async {
    var patchCalled = false;
    final controller = makeController(
      MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse({'data': assetJson(id: 1)});
        }
        patchCalled = true;
        return jsonResponse({});
      }),
    );
    await controller.load(1);

    expect(
      await controller.save(
        name: '',
        description: 'x',
        price: '1',
        deposit: '1',
        pickupPoint: 'x',
      ),
      EditItemResult.missingFields,
    );
    expect(
      await controller.save(
        name: 'x',
        description: 'x',
        price: 'abc',
        deposit: '1',
        pickupPoint: 'x',
      ),
      EditItemResult.invalidPrice,
    );
    expect(
      await controller.save(
        name: 'x',
        description: 'x',
        price: '1',
        deposit: '-5',
        pickupPoint: 'x',
      ),
      EditItemResult.invalidDeposit,
    );
    expect(patchCalled, isFalse);
  });

  test('load reports a connection error', () async {
    final controller = makeController(
      MockClient((request) async => throw http.ClientException('offline')),
    );

    await controller.load(1);

    expect(controller.error, 'Connection error');
  });
}

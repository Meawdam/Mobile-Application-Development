import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/add_item/controller/add_item_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

AddItemController makeController(
  MockClient client, {
  FakeAuthservice? auth,
  bool withImageAndDate = true,
}) {
  final controller = AddItemController(
    client: client,
    authService: auth ?? FakeAuthservice(),
  );
  if (withImageAndDate) {
    controller.setPickedImage(Uint8List.fromList([1, 2, 3]), 'camera.jpg');
    controller.setLendingEndDate(DateTime(2030, 1, 1));
  }
  return controller;
}

Future<AddItemResult> submitValid(AddItemController controller) {
  return controller.submit(
    name: 'Camera',
    description: 'Digital camera',
    price: '120',
    deposit: '500',
    pickupPoint: 'Canteen',
  );
}

void main() {
  test('submit sends multipart POST /api/assets with token and fields', () async {
    late http.Request captured;
    final controller = makeController(
      MockClient((request) async {
        captured = request;
        return jsonResponse({'message': 'Asset submitted for admin approval'}, 201);
      }),
    );

    final result = await submitValid(controller);

    expect(result, AddItemResult.success);
    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/assets');
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(captured.headers['content-type'], startsWith('multipart/form-data'));
    expect(captured.body, contains('name="name"'));
    expect(captured.body, contains('Camera'));
    expect(captured.body, contains('name="down_payment"'));
    expect(captured.body, contains('name="price"'));
    expect(captured.body, contains('name="pickup_point"'));
    expect(captured.body, contains('name="return_before"'));
    expect(captured.body, contains('2030-01-01'));
    expect(captured.body, contains('name="image"; filename="camera.jpg"'));
    expect(captured.body, contains('image/jpeg'));
    expect(controller.submitting, isFalse);
  });

  test('submit rejects a missing image without calling the API', () async {
    var called = false;
    final controller = makeController(
      MockClient((request) async {
        called = true;
        return jsonResponse({}, 201);
      }),
      withImageAndDate: false,
    );
    controller.setLendingEndDate(DateTime(2030, 1, 1));

    expect(await submitValid(controller), AddItemResult.missingImage);
    expect(called, isFalse);
  });

  test('submit rejects missing fields, bad price and non-finite deposit', () async {
    final controller = makeController(
      MockClient((request) async => jsonResponse({}, 201)),
    );

    expect(
      await controller.submit(
        name: '',
        description: 'x',
        price: '1',
        deposit: '1',
        pickupPoint: 'x',
      ),
      AddItemResult.missingFields,
    );
    expect(
      await controller.submit(
        name: 'Camera',
        description: 'x',
        price: '1.5',
        deposit: '1',
        pickupPoint: 'x',
      ),
      AddItemResult.invalidPrice,
    );
    expect(
      await controller.submit(
        name: 'Camera',
        description: 'x',
        price: '1',
        deposit: 'NaN',
        pickupPoint: 'x',
      ),
      AddItemResult.invalidDeposit,
    );
  });

  test('submit shows the backend error message on a 400', () async {
    final controller = makeController(
      MockClient(
        (request) async => jsonResponse(
          {'message': 'return_before must be a valid date today or later'},
          400,
        ),
      ),
    );

    expect(await submitValid(controller), AddItemResult.failed);
    expect(controller.error, 'return_before must be a valid date today or later');
  });

  test('submit fails without calling the API when not logged in', () async {
    var called = false;
    final controller = makeController(
      MockClient((request) async {
        called = true;
        return jsonResponse({}, 201);
      }),
      auth: FakeAuthservice(token: null),
    );

    expect(await submitValid(controller), AddItemResult.failed);
    expect(controller.error, 'Please log in again');
    expect(called, isFalse);
  });

  test('submit reports a connection error', () async {
    final controller = makeController(
      MockClient((request) async => throw http.ClientException('offline')),
    );

    expect(await submitValid(controller), AddItemResult.failed);
    expect(controller.error, 'Connection error');
  });
}

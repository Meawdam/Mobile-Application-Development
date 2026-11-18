import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_helpers.dart';

MyLendingController makeController(MockClient client) =>
    MyLendingController(client: client, authService: FakeAuthservice());

void main() {
  test('load calls GET /api/assets/mine and maps the items', () async {
    late http.Request captured;
    final controller = makeController(
      MockClient((request) async {
        captured = request;
        return jsonResponse({
          'data': [
            assetJson(id: 1, name: 'My camera'),
            assetJson(id: 2, name: 'My tripod', approval: 'pending'),
          ],
        });
      }),
    );

    await controller.load();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/assets/mine');
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(controller.items.map((a) => a.name), ['My camera', 'My tripod']);
    expect(controller.items.last.approval, 'pending');
    expect(controller.error, isNull);
    expect(controller.loading, isFalse);
  });

  test('load shows the backend message on failure', () async {
    final controller = makeController(
      MockClient((request) async => jsonResponse({'message': 'Invalid token'}, 403)),
    );

    await controller.load();

    expect(controller.error, 'Invalid token');
    expect(controller.items, isEmpty);
  });

  test('load reports a connection error', () async {
    final controller = makeController(
      MockClient((request) async => throw http.ClientException('offline')),
    );

    await controller.load();

    expect(controller.error, 'Connection error');
  });

  test('deleteAsset calls DELETE /api/assets/:id and removes the item', () async {
    late http.Request deleteRequest;
    final controller = makeController(
      MockClient((request) async {
        if (request.method == 'DELETE') {
          deleteRequest = request;
          return jsonResponse({'message': 'Asset deleted successfully'});
        }
        return jsonResponse({
          'data': [assetJson(id: 1), assetJson(id: 2, name: 'My tripod')],
        });
      }),
    );
    await controller.load();

    final error = await controller.deleteAsset(1);

    expect(error, isNull);
    expect(deleteRequest.url.path, '/api/assets/1');
    expect(deleteRequest.headers['Authorization'], 'Bearer test-token');
    expect(controller.items.map((a) => a.id), [2]);
  });

  test('deleteAsset returns the backend message and keeps the item', () async {
    final controller = makeController(
      MockClient((request) async {
        if (request.method == 'DELETE') {
          return jsonResponse(
            {'message': 'Cannot delete an asset that has borrow history'},
            409,
          );
        }
        return jsonResponse({'data': [assetJson(id: 1)]});
      }),
    );
    await controller.load();

    final error = await controller.deleteAsset(1);

    expect(error, 'Cannot delete an asset that has borrow history');
    expect(controller.items.map((a) => a.id), [1]);
  });
}

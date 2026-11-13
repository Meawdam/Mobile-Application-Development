import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/user/user_model.dart';
import 'package:frontend/modules/user/home/controller/home_controller.dart';
import 'package:frontend/services/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('1. initialize loads session user and available assets', () async {
    await AuthSession.instance.saveSession(
      token: 'token',
      user: const UserModel(
        id: 1,
        username: 'mike',
        phoneNumber: '0811111111',
        email: 'mike@example.com',
        role: 'user',
      ),
    );

    final api = FakeAssetApi(available: [
      sampleAsset(id: 1, name: 'Camera'),
      sampleAsset(id: 2, name: 'Lens'),
    ]);
    final controller = HomeController(assetApi: api);

    await controller.initialize();

    expect(controller.user?.username, 'mike');
    expect(controller.items.length, 2);
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
  });

  test('2. search filters assets by query', () async {
    final controller = HomeController(
      assetApi: FakeAssetApi(available: [
        sampleAsset(id: 1, name: 'Camera'),
        sampleAsset(id: 2, name: 'Tripod'),
      ]),
    );

    await controller.search('cam');

    expect(controller.query, 'cam');
    expect(controller.items.single.name, 'Camera');
  });

  test('3. loadItems stores API errors', () async {
    final controller = HomeController(
      assetApi: FakeAssetApi(throwOnGet: true),
    );

    await controller.loadItems();

    expect(controller.items, isEmpty);
    expect(controller.error, 'assets unavailable');
  });
}

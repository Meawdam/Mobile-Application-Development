import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/item_detail/controller/item_detail_controller.dart';

import '../../helpers/test_fakes.dart';

void main() {
  test('1. load fetches asset details by id', () async {
    final controller = ItemDetailController(
      assetApi: FakeAssetApi(byId: sampleAsset(id: 9, name: 'Lens')),
    );

    await controller.load(9);

    expect(controller.asset?.id, 9);
    expect(controller.asset?.name, 'Lens');
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
  });

  test('2. load stores API errors and clears asset', () async {
    final controller = ItemDetailController(
      assetApi: FakeAssetApi(throwOnGet: true),
    );

    await controller.load(1);

    expect(controller.asset, isNull);
    expect(controller.error, 'asset not found');
  });
}

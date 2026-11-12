import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/add_item/controller/add_item_controller.dart';
import 'package:frontend/services/asset_api.dart';

class _FakeAssetApi extends AssetApi {
  bool created = false;

  @override
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
    created = true;
    return AssetModel(
      id: 1,
      ownerId: 1,
      name: name,
      description: description,
      status: 'ready',
      approval: 'pending',
      downPayment: num.parse(downPayment),
      returnBefore: returnBefore,
      price: int.parse(price),
      pickupPoint: pickupPoint,
    );
  }
}

void main() {
  AddItemController readyController(_FakeAssetApi api) {
    final controller = AddItemController(assetApi: api);
    controller.setPickedImage(Uint8List.fromList([1, 2, 3]), 'cam.jpg');
    controller.setLendingEndDate(DateTime(2026, 12, 31));
    return controller;
  }

  test('1. creates an item when the form is valid', () async {
    final api = _FakeAssetApi();
    final result = await readyController(api).submit(
      name: 'Canon Camera',
      description: 'Good condition',
      price: '120',
      deposit: '1500',
      pickupPoint: 'Canteen',
    );

    expect(result, AddItemResult.success);
    expect(api.created, isTrue);
  });

  test('2. rejects empty required fields', () async {
    final result = await readyController(_FakeAssetApi()).submit(
      name: '   ',
      description: 'desc',
      price: '120',
      deposit: '1500',
      pickupPoint: 'Canteen',
    );

    expect(result, AddItemResult.missingFields);
  });

  test('3. rejects a missing image', () async {
    final controller = AddItemController(assetApi: _FakeAssetApi());
    controller.setLendingEndDate(DateTime(2026, 12, 31));

    final result = await controller.submit(
      name: 'Camera',
      description: 'desc',
      price: '120',
      deposit: '1500',
      pickupPoint: 'Canteen',
    );

    expect(result, AddItemResult.missingImage);
  });

  test('4. rejects an invalid price', () async {
    final result = await readyController(_FakeAssetApi()).submit(
      name: 'Camera',
      description: 'desc',
      price: 'abc',
      deposit: '1500',
      pickupPoint: 'Canteen',
    );

    expect(result, AddItemResult.invalidPrice);
  });

  test('5. rejects a missing lending end date', () async {
    final controller = AddItemController(assetApi: _FakeAssetApi());
    controller.setPickedImage(Uint8List.fromList([1]), 'cam.jpg');

    final result = await controller.submit(
      name: 'Camera',
      description: 'desc',
      price: '120',
      deposit: '1500',
      pickupPoint: 'Canteen',
    );

    expect(result, AddItemResult.missingLendingEndDate);
  });
}

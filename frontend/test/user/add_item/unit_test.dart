import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/add_item/controller/add_item_controller.dart';

void main() {
  test('submit adds a valid item to the provided list', () async {
    final items = <AssetModel>[];
    final controller = AddItemController(items: items);
    controller.setPickedImage(Uint8List.fromList([1, 2, 3]), 'camera.jpg');
    controller.setLendingEndDate(DateTime(2030, 1, 1));

    final result = await controller.submit(
      name: 'Camera',
      description: 'Digital camera',
      price: '120',
      deposit: '500',
      pickupPoint: 'Canteen',
    );

    expect(result, AddItemResult.success);
    expect(items, hasLength(1));
    expect(items.single.name, 'Camera');
    expect(items.single.price, 120);
    expect(items.single.downPayment, 500);
    expect(items.single.approval, 'pending');
  });

  test('submit rejects a missing image without adding an item', () async {
    final items = <AssetModel>[];
    final controller = AddItemController(items: items);
    controller.setLendingEndDate(DateTime(2030, 1, 1));

    final result = await controller.submit(
      name: 'Camera',
      description: 'Digital camera',
      price: '120',
      deposit: '500',
      pickupPoint: 'Canteen',
    );

    expect(result, AddItemResult.missingImage);
    expect(items, isEmpty);
  });

  test('submit rejects non-finite deposits', () async {
    final items = <AssetModel>[];
    final controller = AddItemController(items: items);
    controller.setPickedImage(Uint8List.fromList([1]), 'camera.jpg');
    controller.setLendingEndDate(DateTime(2030, 1, 1));

    final result = await controller.submit(
      name: 'Camera',
      description: 'Digital camera',
      price: '120',
      deposit: 'NaN',
      pickupPoint: 'Canteen',
    );

    expect(result, AddItemResult.invalidDeposit);
    expect(items, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';

void main() {
  test('load returns only the current user items', () async {
    final controller = MyLendingController(
      items: [
        const AssetModel(
            id: 1,
            ownerId: 1,
            name: 'My camera',
            description: '',
            status: 'available',
            approval: 'approved',
            downPayment: 0,
            returnBefore: '2030-01-01',
            price: 50,
            pickupPoint: 'Canteen',
          ),
        const AssetModel(
            id: 2,
            ownerId: 2,
            name: 'Other camera',
            description: '',
            status: 'available',
            approval: 'approved',
            downPayment: 0,
            returnBefore: '2030-01-01',
            price: 50,
            pickupPoint: 'Canteen',
          ),
      ],
    );

    await controller.load();

    expect(controller.items.map((item) => item.name), ['My camera']);
  });

  test('deleteAsset removes an owned item from the current list', () async {
    final items = <AssetModel>[
      const AssetModel(
          id: 1,
          ownerId: 1,
          name: 'My camera',
          description: '',
          status: 'available',
          approval: 'approved',
          downPayment: 0,
          returnBefore: '2030-01-01',
          price: 50,
          pickupPoint: 'Canteen',
        ),
    ];
    final controller = MyLendingController(items: items);
    await controller.load();

    final error = await controller.deleteAsset(1);

    expect(error, isNull);
    expect(items, isEmpty);
    expect(controller.items, isEmpty);
  });
}

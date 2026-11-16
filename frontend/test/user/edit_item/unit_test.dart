import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/edit_item/controller/edit_item_controller.dart';

void main() {
  test('save updates the local item', () async {
    final items = <AssetModel>[
      const AssetModel(
          id: 2,
          ownerId: 1,
          name: 'Camera',
          description: 'Old description',
          status: 'available',
          approval: 'approved',
          downPayment: 100,
          returnBefore: '2030-01-01',
          price: 50,
          pickupPoint: 'Old location',
        ),
    ];
    final controller = EditItemController(items: items);
    await controller.load(2);

    final result = await controller.save(
      name: 'Updated camera',
      description: 'Updated description',
      price: '75',
      deposit: '250',
      pickupPoint: 'New location',
    );

    expect(result, EditItemResult.success);
    expect(items.single.name, 'Updated camera');
    expect(items.single.price, 75);
    expect(items.single.downPayment, 250);
    expect(items.single.pickupPoint, 'New location');
  });

  test('save rejects a non-finite deposit', () async {
    final controller = EditItemController(
      items: [
        const AssetModel(
            id: 2,
            ownerId: 1,
            name: 'Camera',
            description: 'Camera',
            status: 'available',
            approval: 'approved',
            downPayment: 100,
            returnBefore: '2030-01-01',
            price: 50,
            pickupPoint: 'Canteen',
          ),
      ],
    );
    await controller.load(2);

    final result = await controller.save(
      name: 'Camera',
      description: 'Camera',
      price: '75',
      deposit: 'Infinity',
      pickupPoint: 'Canteen',
    );

    expect(result, EditItemResult.invalidDeposit);
  });
}

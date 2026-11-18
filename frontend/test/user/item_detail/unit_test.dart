import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/item_detail/controller/item_detail_controller.dart';

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
  });

  test('load reports a missing item and clears the asset', () async {
    final controller = ItemDetailController();

    await controller.load(1);

    expect(controller.asset, isNull);
    expect(controller.error, 'Item not found');
  });
}

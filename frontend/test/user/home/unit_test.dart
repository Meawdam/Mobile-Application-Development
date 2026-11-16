import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/home/controller/home_controller.dart';

void main() {
  test('initialize loads approved available items and supports search', () async {
    final controller = HomeController(
      availableItems: const [
        AssetModel(
            id: 1,
            ownerId: 2,
            name: 'Camera',
            description: 'Digital camera',
            status: 'available',
            approval: 'approved',
            downPayment: 0,
            returnBefore: '2030-01-01',
            price: 50,
            pickupPoint: 'Canteen',
        ),
        AssetModel(
            id: 2,
            ownerId: 2,
            name: 'Lens',
            description: 'Camera lens',
            status: 'available',
            approval: 'pending',
            downPayment: 0,
            returnBefore: '2030-01-01',
            price: 30,
            pickupPoint: 'Canteen',
        ),
        AssetModel(
            id: 3,
            ownerId: 2,
            name: 'Tripod',
            description: 'Support stand',
            status: 'borrowed',
            approval: 'approved',
            downPayment: 0,
            returnBefore: '2030-01-01',
            price: 20,
            pickupPoint: 'Canteen',
        ),
      ],
    );

    await controller.initialize();

    expect(controller.user?.username, 'Guest');
    expect(controller.items.map((item) => item.name), ['Camera']);

    await controller.search('digital');

    expect(controller.query, 'digital');
    expect(controller.items.map((item) => item.name), ['Camera']);
  });
}

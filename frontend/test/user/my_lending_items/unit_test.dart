import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/modules/user/shared/model/lending_item_model.dart';
import 'package:frontend/services/asset_api.dart';

class _FakeAssetApi extends AssetApi {
  List<AssetModel> assets = [
    const AssetModel(
      id: 1,
      ownerId: 1,
      name: 'Camera',
      description: 'desc',
      status: 'ready',
      approval: 'approved',
      downPayment: 100,
      returnBefore: '2030-01-31',
      price: 50,
      pickupPoint: 'Canteen',
    ),
    const AssetModel(
      id: 2,
      ownerId: 1,
      name: 'Lens',
      description: 'desc',
      status: 'borrowed',
      approval: 'approved',
      downPayment: 200,
      returnBefore: '2030-01-31',
      price: 80,
      pickupPoint: 'Library',
    ),
  ];

  @override
  Future<List<AssetModel>> getMyAssets() async => List.of(assets);

  @override
  Future<void> deleteAsset(int id) async {
    assets.removeWhere((a) => a.id == id);
  }
}

void main() {
  test('1. LendingItem.fromMap converts backend data correctly', () {
    final item = LendingItem.fromMap({
      'id': 7,
      'owner_id': 3,
      'name': 'Canon Camera',
      'price': 120,
      'down_payment': '1500.00',
      'pickup_point': 'Building 3',
      'return_before': '2030-05-09',
      'status': 'borrowed',
      'approval': 'not approve',
    });

    expect(item.id, '7');
    expect(item.pricePerDay, 120);
    expect(item.deposit, 1500);
    expect(item.returnBefore, DateTime(2030, 5, 9));
    expect(item.status, ItemStatus.borrowed);
    expect(item.approval, ApprovalStatus.notApproved);
  });

  test('2. load fetches the owner assets from the API', () async {
    final controller = MyLendingController(assetApi: _FakeAssetApi());
    await controller.load();

    expect(controller.loading, isFalse);
    expect(controller.items.length, 2);
    expect(controller.items.first.name, 'Camera');
  });

  test('3. deleteAsset removes an item and reloads the list', () async {
    final api = _FakeAssetApi();
    final controller = MyLendingController(assetApi: api);
    await controller.load();

    final error = await controller.deleteAsset(1);

    expect(error, isNull);
    expect(controller.items.map((i) => i.id), [2]);
  });
}

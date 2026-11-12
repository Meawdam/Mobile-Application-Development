import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/edit_item/controller/edit_item_controller.dart';
import 'package:frontend/services/asset_api.dart';

class _FakeAssetApi extends AssetApi {
  AssetModel asset = const AssetModel(
    id: 1,
    ownerId: 1,
    name: 'Canon Camera',
    description: 'Good condition',
    status: 'ready',
    approval: 'approved',
    downPayment: 1500,
    returnBefore: '2026-12-31',
    price: 120,
    pickupPoint: 'Canteen',
  );

  @override
  Future<AssetModel> getAssetById(int id) async => asset;

  @override
  Future<AssetModel> updateAsset({
    required int id,
    required String name,
    required String description,
    required String downPayment,
    required String price,
    required String pickupPoint,
    required String returnBefore,
  }) async {
    asset = AssetModel(
      id: id,
      ownerId: asset.ownerId,
      name: name,
      description: description,
      status: asset.status,
      approval: asset.approval,
      downPayment: num.parse(downPayment),
      returnBefore: returnBefore,
      price: int.parse(price),
      pickupPoint: pickupPoint,
    );
    return asset;
  }
}

void main() {
  test('1. loads an asset and saves valid edits', () async {
    final api = _FakeAssetApi();
    final controller = EditItemController(assetApi: api);
    await controller.load(1);

    final result = await controller.save(
      name: 'Canon Camera',
      description: 'Good condition',
      price: '200',
      deposit: '2000',
      pickupPoint: 'Library',
    );

    expect(result, EditItemResult.success);
    expect(controller.asset!.price, 200);
    expect(controller.asset!.downPayment, 2000);
    expect(controller.asset!.pickupPoint, 'Library');
  });

  test('2. rejects empty required fields', () async {
    final controller = EditItemController(assetApi: _FakeAssetApi());
    await controller.load(1);

    final result = await controller.save(
      name: '',
      description: 'Good condition',
      price: '200',
      deposit: '2000',
      pickupPoint: 'Library',
    );

    expect(result, EditItemResult.missingFields);
  });

  test('3. rejects an invalid price', () async {
    final controller = EditItemController(assetApi: _FakeAssetApi());
    await controller.load(1);

    final result = await controller.save(
      name: 'Canon Camera',
      description: 'Good condition',
      price: 'abc',
      deposit: '2000',
      pickupPoint: 'Library',
    );

    expect(result, EditItemResult.invalidPrice);
    expect(controller.asset!.price, 120);
  });
}

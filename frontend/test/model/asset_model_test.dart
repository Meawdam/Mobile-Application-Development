import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/asset/asset_model.dart';

void main() {
  test('fromJson maps snake_case backend fields', () {
    final asset = AssetModel.fromJson({
      'id': '7',
      'owner_id': 3,
      'owner_username': 'mike',
      'image': '/uploads/cam.jpg',
      'name': 'Camera',
      'description': 'Nice',
      'status': 'ready',
      'approval': 'approved',
      'approval_message': null,
      'down_payment': '1500.50',
      'return_before': '2030-05-09T00:00:00.000Z',
      'price': 120,
      'pickup_point': 'Building 3',
    });

    expect(asset.id, 7);
    expect(asset.ownerId, 3);
    expect(asset.ownerUsername, 'mike');
    expect(asset.name, 'Camera');
    expect(asset.downPayment, 1500.50);
    expect(asset.returnBefore, '2030-05-09');
    expect(asset.price, 120);
    expect(asset.pickupPoint, 'Building 3');
  });

  test('fromJson falls back to empty/zero values for missing fields', () {
    final asset = AssetModel.fromJson({});

    expect(asset.id, 0);
    expect(asset.name, '');
    expect(asset.price, 0);
    expect(asset.returnBefore, '');
  });

  test('imageUrl resolves relative media paths', () {
    final asset = AssetModel.fromJson({
      'id': 1,
      'owner_id': 1,
      'name': 'Cam',
      'description': '',
      'status': 'ready',
      'approval': 'approved',
      'down_payment': 0,
      'return_before': '2030-01-01',
      'price': 1,
      'pickup_point': 'A',
      'image': '/uploads/a.jpg',
    });

    expect(asset.imageUrl.contains('/uploads/a.jpg'), isTrue);
  });
}

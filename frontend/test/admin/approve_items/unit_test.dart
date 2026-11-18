import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/approve_items/controller/approve_items_controller.dart';
import 'package:frontend/modules/admin/approve_items/model/approve_item_model.dart';

void main() {
  late ApproveItemsController controller;

  setUp(() => controller = ApproveItemsController());
  tearDown(() => controller.dispose());

  test('ApproveItem converts to and from a map', () {
    const item = ApproveItem(
      id: 'item-1',
      name: 'Calculator',
      owner: 'Somchai',
      time: '2026-11-18',
      description: 'Scientific calculator',
    );

    expect(ApproveItem.fromMap(item.toMap()).toMap(), item.toMap());
  });

  test('Items are exposed as an unmodifiable list', () {
    expect(() => controller.items.clear(), throwsUnsupportedError);
  });

  test('Rejecting without a reason returns false without an API call', () async {
    expect(await controller.rejectItem('item-1', '   '), isFalse);
    expect(controller.errorMessage, 'Please provide a reason for the rejection.');
  });
}


import 'package:flutter_test/flutter_test.dart';
//import '../lib/admin/controller/approve_items_controller.dart';
import 'package:frontend/modules/admin/controllers/approve_items_controller.dart';
void main() {
  late ApproveItemsController controller;

  setUp(() {
    controller = ApproveItemsController();
  });

  tearDown(() {
    controller.dispose();
  });

  test('Initially has 3 pending items', () {
    expect(controller.pendingCount, 3);
    expect(controller.items.length, 3);
  });

  test('Approve item successfully', () {
    final result = controller.approveItem('item1');

    expect(result, true);
    expect(controller.pendingCount, 2);
    expect(
      controller.items.any((item) => item.id == 'item1'),
      false,
    );
  });

  test('Reject item with a reason successfully', () {
    final result = controller.rejectItem(
      'item2',
      'Item information is incorrect',
    );

    expect(result, true);
    expect(controller.pendingCount, 2);
    expect(
      controller.items.any((item) => item.id == 'item2'),
      false,
    );
  });

  test('Cannot reject item with an empty reason', () {
    final result = controller.rejectItem('item1', '');

    expect(result, false);
    expect(controller.pendingCount, 3);
  });

  test('Cannot reject item with only spaces as reason', () {
    final result = controller.rejectItem('item1', '   ');

    expect(result, false);
    expect(controller.pendingCount, 3);
  });

  test('Cannot approve an item that does not exist', () {
    final result = controller.approveItem('unknown');

    expect(result, false);
    expect(controller.pendingCount, 3);
  });

  test('Cannot reject an item that does not exist', () {
    final result = controller.rejectItem(
      'unknown',
      'Invalid item',
    );

    expect(result, false);
    expect(controller.pendingCount, 3);
  });
}


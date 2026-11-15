
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/admin/controller/approve_items_controller.dart';
import '../../../lib/admin/model/approve_item_model.dart';

void main() {
  late ApproveItemsController controller;

  setUp(() {
    controller = ApproveItemsController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('ApproveItemsController Tests', () {
    test('Initially has 3 pending items', () {
      expect(controller.pendingCount, 3);
      expect(controller.items.length, 3);
    });

    test('Returns an unmodifiable items list', () {
      expect(
        () => controller.items.clear(),
        throwsUnsupportedError,
      );
    });

    test('Approves an existing item', () {
      final result = controller.approveItem('item1');

      expect(result, isTrue);
      expect(controller.pendingCount, 2);
      expect(
        controller.items.any((item) => item.id == 'item1'),
        isFalse,
      );
    });

    test('Rejects an item with a valid reason', () {
      final result = controller.rejectItem(
        'item2',
        'Item information is incorrect',
      );

      expect(result, isTrue);
      expect(controller.pendingCount, 2);
      expect(
        controller.items.any((item) => item.id == 'item2'),
        isFalse,
      );
    });

    test('Rejects an item when reason contains surrounding spaces', () {
      final result = controller.rejectItem(
        'item1',
        '  Incorrect information  ',
      );

      expect(result, isTrue);
      expect(controller.pendingCount, 2);
    });

    test('Cannot reject an item with an empty reason', () {
      expect(controller.rejectItem('item1', ''), isFalse);
      expect(controller.pendingCount, 3);
    });

    test('Cannot reject an item with only spaces', () {
      expect(controller.rejectItem('item1', '   '), isFalse);
      expect(controller.pendingCount, 3);
    });

    test('Cannot approve an unknown item', () {
      expect(controller.approveItem('unknown'), isFalse);
      expect(controller.pendingCount, 3);
    });

    test('Cannot reject an unknown item', () {
      expect(
        controller.rejectItem('unknown', 'Invalid item'),
        isFalse,
      );
      expect(controller.pendingCount, 3);
    });

    test('Notifies listeners after approving an item', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.approveItem('item1');

      expect(notified, isTrue);
    });

    test('Notifies listeners after rejecting an item', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.rejectItem('item1', 'Invalid information');

      expect(notified, isTrue);
    });

    test('Does not notify listeners when rejection reason is empty', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.rejectItem('item1', '');

      expect(notified, isFalse);
    });
  });

  group('ApproveItem Model Tests', () {
    test('Converts item to map and back', () {
      const item = ApproveItem(
        id: 'item1',
        name: 'Calculator',
        owner: 'Somchai J.',
        time: '30 Oct. 11:10',
        category: 'Calculator',
        description: 'Scientific calculator',
      );

      final restored = ApproveItem.fromMap(item.toMap());

      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.owner, item.owner);
      expect(restored.time, item.time);
      expect(restored.category, item.category);
      expect(restored.description, item.description);
    });
  });
}

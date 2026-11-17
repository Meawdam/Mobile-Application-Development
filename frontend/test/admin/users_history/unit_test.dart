import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/users_history/controller/users_history_controller.dart';

void main() {
  late UsersHistoryController controller;

  setUp(() => controller = UsersHistoryController());
  tearDown(() => controller.dispose());

  group('Suspension reason', () {
    test('Suspending with a reason stores it for the selected user', () {
      final ok = controller.suspendSelectedUser('  Repeated late returns  ');

      expect(ok, isTrue);
      expect(controller.isSelectedUserSuspended, isTrue);
      expect(controller.selectedUserSuspensionReason, 'Repeated late returns');
    });

    test('Blank reason is rejected and the user stays active', () {
      final ok = controller.suspendSelectedUser('   ');

      expect(ok, isFalse);
      expect(controller.isSelectedUserSuspended, isFalse);
      expect(controller.selectedUserSuspensionReason, isNull);
    });

    test('Activating clears the reason and restores access', () {
      controller.suspendSelectedUser('Spam');
      controller.activateSelectedUser();

      expect(controller.isSelectedUserSuspended, isFalse);
      expect(controller.selectedUserSuspensionReason, isNull);
    });

    test('Reasons are kept per user', () {
      controller.suspendSelectedUser('Reason A');
      controller.selectUser('user2');

      expect(controller.selectedUserSuspensionReason, isNull);

      controller.suspendSelectedUser('Reason B');
      controller.selectUser('user1');

      expect(controller.selectedUserSuspensionReason, 'Reason A');
    });

    test('Notifies listeners when suspending and activating', () {
      var count = 0;
      controller.addListener(() => count++);

      controller.suspendSelectedUser('x');
      controller.activateSelectedUser();

      expect(count, 2);
    });
  });
}

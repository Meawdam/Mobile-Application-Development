import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/users_history/controller/users_history_controller.dart';
import 'package:frontend/modules/admin/users_history/model/user_history_model.dart';

void main() {
  late UsersHistoryController controller;

  setUp(() => controller = UsersHistoryController());
  tearDown(() => controller.dispose());

  test('User and activity models convert to and from maps', () {
    final user = UserHistoryUser(
      id: 'user-1',
      name: 'Somchai',
      initial: 'S',
      total: 3,
      lending: 1,
      overdue: 0,
      activities: const [
        UserHistoryActivity(
          date: '2026-11-18',
          category: 'Finance',
          title: 'Payment completed',
          performedBy: 'Somchai',
        ),
      ],
    );

    expect(UserHistoryUser.fromMap(user.toMap()).toMap(), user.toMap());
  });

  test('Activity filters can be changed and reset', () {
    controller.setFilter('Finance');
    expect(controller.selectedFilter, 'Finance');

    controller.searchActivities('payment');
    expect(controller.activitySearch, 'payment');

    controller.resetFilters();
    expect(controller.selectedFilter, 'All');
    expect(controller.activitySearch, isEmpty);
    expect(controller.userSearch, isEmpty);
  });

  test('Suspension requires a selected user', () async {
    expect(await controller.suspendSelectedUser('Policy violation'), isFalse);
    expect(controller.errorMessage, 'Please select a user');
  });
}

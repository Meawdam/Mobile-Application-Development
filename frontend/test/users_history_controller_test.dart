
import 'package:flutter_test/flutter_test.dart';

import '../lib/admin/controller/users_history_controller.dart';

void main() {
  late UsersHistoryController controller;

  setUp(() {
    controller = UsersHistoryController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('UsersHistoryController Unit Tests', () {

    test('à¹€à¸£à¸´à¹ˆà¸¡à¸•à¹‰à¸™à¹€à¸¥à¸·à¸­à¸à¸œà¸¹à¹‰à¹ƒà¸Šà¹‰ Somchai J.', () {
      expect(controller.selectedUserId, 'user1');
      expect(controller.selectedUser.name, 'Somchai J.');
    });

    test('à¹à¸ªà¸”à¸‡à¸œà¸¹à¹‰à¹ƒà¸Šà¹‰à¸—à¸±à¹‰à¸‡à¸«à¸¡à¸” 3 à¸„à¸™', () {
      expect(controller.users.length, 3);
      expect(controller.filteredUsers.length, 3);
    });

    test('à¸„à¹‰à¸™à¸«à¸²à¸œà¸¹à¹‰à¹ƒà¸Šà¹‰à¸”à¹‰à¸§à¸¢à¸Šà¸·à¹ˆà¸­à¸šà¸²à¸‡à¸ªà¹ˆà¸§à¸™à¹„à¸”à¹‰', () {
      controller.searchUsers('Natt');

      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.name, 'Nattapat P.');
    });

    test('à¸„à¹‰à¸™à¸«à¸²à¹‚à¸”à¸¢à¹„à¸¡à¹ˆà¸ªà¸™à¸•à¸±à¸§à¸žà¸´à¸¡à¸žà¹Œà¹€à¸¥à¹‡à¸à¹à¸¥à¸°à¹ƒà¸«à¸à¹ˆ', () {
      controller.searchUsers('som');

      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.name, 'Somchai J.');
    });

    test('à¸„à¹‰à¸™à¸«à¸²à¸Šà¸·à¹ˆà¸­à¸—à¸µà¹ˆà¹„à¸¡à¹ˆà¸¡à¸µà¸­à¸¢à¸¹à¹ˆà¹à¸¥à¹‰à¸§à¸•à¹‰à¸­à¸‡à¹„à¸”à¹‰à¸œà¸¥à¸¥à¸±à¸žà¸˜à¹Œà¸§à¹ˆà¸²à¸‡', () {
      controller.searchUsers('Unknown');

      expect(controller.filteredUsers, isEmpty);
    });

    test('à¹€à¸¥à¸·à¸­à¸à¸œà¸¹à¹‰à¹ƒà¸Šà¹‰à¸„à¸™à¸­à¸·à¹ˆà¸™à¹à¸¥à¹‰à¸§à¸‚à¹‰à¸­à¸¡à¸¹à¸¥à¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™', () {
      controller.selectUser('user2');

      expect(controller.selectedUserId, 'user2');
      expect(controller.selectedUser.name, 'Suphaporn K.');
      expect(controller.selectedFilter, 'All');
    });

    test('à¹€à¸¥à¸·à¸­à¸ ID à¸—à¸µà¹ˆà¹„à¸¡à¹ˆà¸¡à¸µà¸­à¸¢à¸¹à¹ˆà¸ˆà¸°à¹„à¸¡à¹ˆà¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™à¸œà¸¹à¹‰à¹ƒà¸Šà¹‰', () {
      controller.selectUser('unknown');

      expect(controller.selectedUserId, 'user1');
    });

    test('à¸à¸£à¸­à¸‡ Activity à¹€à¸‰à¸žà¸²à¸° Rental à¹„à¸”à¹‰', () {
      controller.setFilter('Rental');

      expect(controller.filteredActivities.length, 2);

      expect(
        controller.filteredActivities.every(
          (activity) => activity.category == 'Rental',
        ),
        isTrue,
      );
    });

    test('à¸à¸£à¸­à¸‡ Activity à¹€à¸‰à¸žà¸²à¸° Finance à¹„à¸”à¹‰', () {
      controller.setFilter('Finance');

      expect(controller.filteredActivities.length, 2);

      expect(
        controller.filteredActivities.every(
          (activity) => activity.category == 'Finance',
        ),
        isTrue,
      );
    });

    test('à¸„à¹‰à¸™à¸«à¸² Activity à¸ˆà¸²à¸à¸Šà¸·à¹ˆà¸­à¸£à¸²à¸¢à¸à¸²à¸£à¹„à¸”à¹‰', () {
      controller.searchActivities('Lab Equipment');

      expect(controller.filteredActivities.length, 1);
      expect(
        controller.filteredActivities.first.title,
        'Borrowed Lab Equipment',
      );
    });

    test('Reset filters à¸„à¸·à¸™à¸„à¹ˆà¸²à¸•à¸±à¸§à¸à¸£à¸­à¸‡à¹€à¸›à¹‡à¸™ All', () {
      controller.setFilter('Finance');
      controller.searchActivities('Payment');

      controller.resetFilters();

      expect(controller.selectedFilter, 'All');
      expect(controller.activitySearch, '');
      expect(controller.filteredActivities.length, 4);
    });

    test('Suspend Account à¹„à¸”à¹‰', () {
      expect(controller.isSelectedUserSuspended, false);

      controller.toggleSuspend();

      expect(controller.isSelectedUserSuspended, true);
    });

    test('Activate Account à¹„à¸”à¹‰à¸«à¸¥à¸±à¸‡à¸ˆà¸²à¸ Suspend', () {
      controller.toggleSuspend();
      controller.toggleSuspend();

      expect(controller.isSelectedUserSuspended, false);
    });

    test('Controller à¹à¸ˆà¹‰à¸‡à¸à¸²à¸£à¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™à¹à¸›à¸¥à¸‡à¸‚à¹‰à¸­à¸¡à¸¹à¸¥', () {
      var notified = false;

      controller.addListener(() {
        notified = true;
      });

      controller.selectUser('user2');

      expect(notified, true);
    });

  });
}

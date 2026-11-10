
import 'package:flutter/foundation.dart';
import 'package:frontend/modules/admin/medels/user_history_model.dart';

class UsersHistoryController extends ChangeNotifier {
  final List<UserHistoryUser> users = [
    UserHistoryUser(
      id: 'user1',
      name: 'Somchai J.',
      initial: 'S',
      total: 10,
      lending: 6,
      overdue: 1,
      activities: [
        UserHistoryActivity(
          date: '30 Oct. 11:12',
          category: 'Finance',
          title: 'Payment successful 245฿',
          performedBy: 'User',
        ),
        UserHistoryActivity(
          date: '29 Oct. 14:30',
          category: 'Rental',
          title: 'Borrowed Lab Equipment',
          performedBy: 'User',
        ),
        UserHistoryActivity(
          date: '28 Oct. 09:15',
          category: 'Rental',
          title: 'Item returned successfully',
          performedBy: 'User',
        ),
        UserHistoryActivity(
          date: '27 Oct. 16:20',
          category: 'Finance',
          title: 'Late fee payment 50฿',
          performedBy: 'User',
        ),
      ],
    ),
    UserHistoryUser(
      id: 'user2',
      name: 'Suphaporn K.',
      initial: 'S',
      total: 8,
      lending: 4,
      overdue: 0,
      activities: [
        UserHistoryActivity(
          date: '30 Oct. 10:30',
          category: 'Rental',
          title: 'Borrowed Calculator',
          performedBy: 'User',
        ),
        UserHistoryActivity(
          date: '29 Oct. 13:45',
          category: 'Finance',
          title: 'Payment successful 120฿',
          performedBy: 'User',
        ),
        UserHistoryActivity(
          date: '27 Oct. 11:00',
          category: 'Rental',
          title: 'Item returned successfully',
          performedBy: 'User',
        ),
      ],
    ),
    UserHistoryUser(
      id: 'user3',
      name: 'Nattapat P.',
      initial: 'N',
      total: 12,
      lending: 7,
      overdue: 2,
      activities: [
        UserHistoryActivity(
          date: '30 Oct. 15:20',
          category: 'Finance',
          title: 'Payment successful 300฿',
          performedBy: 'User',
        ),
        UserHistoryActivity(
          date: '29 Oct. 09:10',
          category: 'Rental',
          title: 'Borrowed Textbook',
          performedBy: 'User',
        ),
        UserHistoryActivity(
          date: '28 Oct. 14:00',
          category: 'Rental',
          title: 'Overdue item recorded',
          performedBy: 'System',
        ),
      ],
    ),
  ];

  String selectedUserId = 'user1';
  String selectedFilter = 'All';
  String userSearch = '';
  String activitySearch = '';

  final Set<String> suspendedUsers = {};

  UserHistoryUser get selectedUser {
    return users.firstWhere(
      (user) => user.id == selectedUserId,
    );
  }

  List<UserHistoryUser> get filteredUsers {
    final query = userSearch.trim().toLowerCase();

    if (query.isEmpty) return users;

    return users.where((user) {
      return user.name.toLowerCase().contains(query);
    }).toList();
  }

  List<UserHistoryActivity> get filteredActivities {
    return selectedUser.activities.where((activity) {
      final matchesFilter = selectedFilter == 'All' ||
          activity.category == selectedFilter;

      final query = activitySearch.trim().toLowerCase();

      final matchesSearch =
          activity.title.toLowerCase().contains(query) ||
          activity.category.toLowerCase().contains(query) ||
          activity.performedBy.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  bool get isSelectedUserSuspended {
    return suspendedUsers.contains(selectedUserId);
  }

  void selectUser(String userId) {
    if (!users.any((user) => user.id == userId)) return;

    selectedUserId = userId;
    selectedFilter = 'All';
    activitySearch = '';
    notifyListeners();
  }

  void searchUsers(String query) {
    userSearch = query;
    notifyListeners();
  }

  void searchActivities(String query) {
    activitySearch = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    if (!['All', 'Rental', 'Finance'].contains(filter)) return;

    selectedFilter = filter;
    notifyListeners();
  }

  void resetFilters() {
    selectedFilter = 'All';
    activitySearch = '';
    notifyListeners();
  }

  void toggleSuspend() {
    if (isSelectedUserSuspended) {
      suspendedUsers.remove(selectedUserId);
    } else {
      suspendedUsers.add(selectedUserId);
    }

    notifyListeners();
  }
}

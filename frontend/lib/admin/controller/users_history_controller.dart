import 'package:flutter/foundation.dart';
import '../model/user_history_model.dart';

class UsersHistoryController extends ChangeNotifier {
  final List<UserHistoryUser> users = [
    UserHistoryUser(
      id: 'user1', name: 'Somchai J.', initial: 'S', total: 10, lending: 6, overdue: 1,
      activities: [
        UserHistoryActivity(date: '30 Oct. 11:12', category: 'Finance', title: 'Payment successful 245฿', performedBy: 'User'),
        UserHistoryActivity(date: '29 Oct. 14:30', category: 'Rental', title: 'Borrowed Lab Equipment', performedBy: 'User'),
        UserHistoryActivity(date: '28 Oct. 09:15', category: 'Rental', title: 'Item returned successfully', performedBy: 'User'),
        UserHistoryActivity(date: '27 Oct. 16:20', category: 'Finance', title: 'Late fee payment 50฿', performedBy: 'User'),
      ],
    ),
    UserHistoryUser(
      id: 'user2', name: 'Suphaporn K.', initial: 'S', total: 8, lending: 4, overdue: 0,
      activities: [
        UserHistoryActivity(date: '30 Oct. 10:30', category: 'Rental', title: 'Borrowed Calculator', performedBy: 'User'),
        UserHistoryActivity(date: '29 Oct. 13:45', category: 'Finance', title: 'Payment successful 120฿', performedBy: 'User'),
        UserHistoryActivity(date: '27 Oct. 11:00', category: 'Rental', title: 'Item returned successfully', performedBy: 'User'),
      ],
    ),
    UserHistoryUser(
      id: 'user3', name: 'Nattapat P.', initial: 'N', total: 12, lending: 7, overdue: 2,
      activities: [
        UserHistoryActivity(date: '30 Oct. 15:20', category: 'Finance', title: 'Payment successful 300฿', performedBy: 'User'),
        UserHistoryActivity(date: '29 Oct. 09:10', category: 'Rental', title: 'Borrowed Textbook', performedBy: 'User'),
        UserHistoryActivity(date: '28 Oct. 14:00', category: 'Rental', title: 'Overdue item recorded', performedBy: 'System'),
      ],
    ),
  ];

  String selectedUserId = 'user1';
  String selectedFilter = 'All';
  String userSearch = '';
  String activitySearch = '';
  final Set<String> suspendedUsers = {};
  final Map<String, String> suspensionReasons = {};

  static const availableFilters = ['All', 'Rental', 'Finance'];
  static const rentalRoles = ['Lender', 'Borrower'];

  UserHistoryUser get selectedUser => users.firstWhere((user) => user.id == selectedUserId);

  List<UserHistoryUser> get filteredUsers {
    final query = userSearch.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users.where((user) => user.name.toLowerCase().contains(query)).toList();
  }

  // The current sample data contains borrower-side events only. Lender stays
  // empty until real lender records are supplied; no records are fabricated.
  String rentalRole(UserHistoryActivity activity) {
    if (activity.category != 'Rental') return '';
    final title = activity.title.toLowerCase();
    if (title.startsWith('lent ') || title.startsWith('loaned ') ||
        title.startsWith('listed ') || title.startsWith('provided ')) {
      return 'Lender';
    }
    return 'Borrower';
  }

  List<UserHistoryActivity> get filteredActivities {
    final query = activitySearch.trim().toLowerCase();
    return selectedUser.activities.where((activity) {
      final role = rentalRole(activity);
      final matchesFilter = switch (selectedFilter) {
        'All' => true,
        'Rental' => activity.category == 'Rental',
        'Finance' => activity.category == 'Finance',
        'Lender' => role == 'Lender',
        'Borrower' => role == 'Borrower',
        _ => true,
      };
      final matchesSearch = activity.title.toLowerCase().contains(query) ||
          activity.category.toLowerCase().contains(query) ||
          activity.performedBy.toLowerCase().contains(query) || role.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  bool get isSelectedUserSuspended => suspendedUsers.contains(selectedUserId);

  String? get selectedUserSuspensionReason => suspensionReasons[selectedUserId];

  void selectUser(String userId) {
    if (!users.any((user) => user.id == userId)) return;
    selectedUserId = userId;
    selectedFilter = 'All';
    activitySearch = '';
    notifyListeners();
  }

  void searchUsers(String query) { userSearch = query; notifyListeners(); }
  void searchActivities(String query) { activitySearch = query; notifyListeners(); }

  void setFilter(String filter) {
    if (![...availableFilters, ...rentalRoles].contains(filter)) return;
    selectedFilter = filter;
    notifyListeners();
  }

  void resetFilters() {
    selectedFilter = 'All';
    activitySearch = '';
    notifyListeners();
  }

  /// Suspends the selected user. A non-empty reason is required.
  /// Returns false (and changes nothing) when the reason is blank.
  bool suspendSelectedUser(String reason) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return false;
    suspendedUsers.add(selectedUserId);
    suspensionReasons[selectedUserId] = trimmed;
    notifyListeners();
    return true;
  }

  /// Re-activates the selected user and clears the stored reason.
  void activateSelectedUser() {
    suspendedUsers.remove(selectedUserId);
    suspensionReasons.remove(selectedUserId);
    notifyListeners();
  }

  void toggleSuspend() {
    if (isSelectedUserSuspended) {
      suspendedUsers.remove(selectedUserId);
      suspensionReasons.remove(selectedUserId);
    } else {
      suspendedUsers.add(selectedUserId);
    }
    notifyListeners();
  }
}
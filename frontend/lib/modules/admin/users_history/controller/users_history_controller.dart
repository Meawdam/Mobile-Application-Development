import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../services/auth_service.dart';
import '../model/user_history_model.dart';

class UsersHistoryController extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:3000';

  final Authservice _authService = Authservice();

  final List<UserHistoryUser> _users = [];
  final Map<String, bool> _suspendedUsers = {};
  final Map<String, String> _suspensionReasons = {};

  bool _isLoadingUsers = false;
  bool _isLoadingActivities = false;
  String? _errorMessage;

  String? _selectedUserId;
  String _selectedFilter = 'All';
  String _userSearch = '';
  String _activitySearch = '';

  List<UserHistoryUser> get users => List.unmodifiable(_users);

  String? get selectedUserId => _selectedUserId;

  String get selectedFilter => _selectedFilter;

  String get userSearch => _userSearch;

  String get activitySearch => _activitySearch;

  bool get isLoadingUsers => _isLoadingUsers;

  bool get isLoadingActivities => _isLoadingActivities;

  String? get errorMessage => _errorMessage;

  UserHistoryUser get selectedUser {
    return _users.firstWhere(
      (user) => user.id == _selectedUserId,
      orElse: () => UserHistoryUser(
        id: '',
        name: 'User information not found',
        initial: '-',
        total: 0,
        lending: 0,
        overdue: 0,
        activities: [],
      ),
    );
  }

  bool get isSelectedUserSuspended {
    if (_selectedUserId == null) return false;
    return _suspendedUsers[_selectedUserId] ?? false;
  }

  bool isUserSuspended(String userId) => _suspendedUsers[userId] ?? false;

  String? get selectedUserSuspensionReason {
    if (_selectedUserId == null) return null;
    return _suspensionReasons[_selectedUserId];
  }

  List<UserHistoryUser> get filteredUsers {
    final keyword = _userSearch.trim().toLowerCase();

    if (keyword.isEmpty) {
      return List.unmodifiable(_users);
    }

    return _users.where((user) {
      return user.name.toLowerCase().contains(keyword) ||
          user.id.toLowerCase().contains(keyword);
    }).toList();
  }

  String rentalRole(UserHistoryActivity activity) {
    final text = '${activity.title} ${activity.performedBy}'.toLowerCase();

    if (text.contains('lend') || text.contains('ให้ยืม')) {
      return 'Lender';
    }

    if (text.contains('borrow') || text.contains('ยืม')) {
      return 'Borrower';
    }

    return 'Rental';
  }

  List<UserHistoryActivity> get filteredActivities {
    final keyword = _activitySearch.trim().toLowerCase();

    return selectedUser.activities.where((activity) {
      final category = activity.category.toLowerCase();
      final role = rentalRole(activity);

      bool matchesFilter;

      switch (_selectedFilter.toLowerCase()) {
        case 'rental':
          matchesFilter = category == 'rental';
          break;
        case 'finance':
          matchesFilter = category == 'finance';
          break;
        case 'lender':
          matchesFilter = category == 'rental' && role == 'Lender';
          break;
        case 'borrower':
          matchesFilter = category == 'rental' && role == 'Borrower';
          break;
        default:
          matchesFilter = true;
      }

      final matchesSearch =
          keyword.isEmpty ||
          activity.title.toLowerCase().contains(keyword) ||
          activity.category.toLowerCase().contains(keyword) ||
          activity.performedBy.toLowerCase().contains(keyword);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> fetchUsers() async {
    _isLoadingUsers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final response = await http
          .get(Uri.parse('$_baseUrl/api/users'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(_getErrorMessage(response));
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map || decoded['data'] is! List) {
        throw Exception('User data format is incorrect.');
      }

      final userList = (decoded['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      _users.clear();
      _suspendedUsers.clear();
      _suspensionReasons.clear();

      for (final item in userList) {
        final user = _createUser(item);
        _users.add(user);

        _suspendedUsers[user.id] = _toBool(
          _firstValue(item, ['is_suspended', 'suspended']),
        );

        final reason = _firstValue(item, [
          'suspension_reason',
          'suspend_reason',
        ]);

        if (reason != null && reason.toString().isNotEmpty) {
          _suspensionReasons[user.id] = reason.toString();
        }
      }

      if (_users.isEmpty) {
        _selectedUserId = null;
      } else if (!_users.any((user) => user.id == _selectedUserId)) {
        _selectedUserId = _users.first.id;
      }
    } catch (e) {
      _errorMessage = _cleanError(e);
      rethrow;
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }

    if (_selectedUserId != null) {
      await fetchUserDetails(_selectedUserId!);
    }
  }

  Future<void> fetchUserDetails(String userId) async {
    _isLoadingActivities = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/users/$userId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(_getErrorMessage(response));
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map || decoded['data'] is! Map) {
        throw Exception('The user detail format is incorrect.');
      }

      final data = Map<String, dynamic>.from(decoded['data'] as Map);

      final index = _users.indexWhere((user) => user.id == userId);

      if (index != -1) {
        final oldUser = _users[index];
        final updatedUser = _createUser(data);

        _users[index] = UserHistoryUser(
          id: userId,
          name: updatedUser.name.isNotEmpty ? updatedUser.name : oldUser.name,
          initial: updatedUser.initial,
          total: updatedUser.total,
          lending: updatedUser.lending,
          overdue: updatedUser.overdue,
          activities: oldUser.activities,
        );

        _suspendedUsers[userId] = _toBool(
          _firstValue(data, ['is_suspended', 'suspended']),
        );

        final reason = _firstValue(data, [
          'suspension_reason',
          'suspend_reason',
        ]);

        if (reason != null && reason.toString().isNotEmpty) {
          _suspensionReasons[userId] = reason.toString();
        } else {
          _suspensionReasons.remove(userId);
        }
      }

      await fetchActivities(userId);
    } catch (e) {
      _errorMessage = _cleanError(e);
      rethrow;
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  Future<void> fetchActivities(String userId) async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse(
            '$_baseUrl/api/users/$userId/activities?limit=100&offset=0',
          ),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map || decoded['data'] is! List) {
      throw Exception('Activity history format is invalid.');
    }

    final activities = (decoded['data'] as List)
        .whereType<Map>()
        .map((item) => _createActivity(Map<String, dynamic>.from(item)))
        .toList();

    final index = _users.indexWhere((user) => user.id == userId);

    if (index != -1) {
      final oldUser = _users[index];

      _users[index] = UserHistoryUser(
        id: oldUser.id,
        name: oldUser.name,
        initial: oldUser.initial,
        total: oldUser.total,
        lending: oldUser.lending,
        overdue: oldUser.overdue,
        activities: activities,
      );
    }

    notifyListeners();
  }

  Future<void> selectUser(String userId) async {
    if (!_users.any((user) => user.id == userId)) return;

    _selectedUserId = userId;
    _selectedFilter = 'All';
    _activitySearch = '';

    notifyListeners();

    try {
      await fetchUserDetails(userId);
    } catch (e) {
      debugPrint('Select user error: $e');
    }
  }

  void searchUsers(String value) {
    _userSearch = value;
    notifyListeners();
  }

  void searchActivities(String value) {
    _activitySearch = value;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void resetFilters() {
    _selectedFilter = 'All';
    _userSearch = '';
    _activitySearch = '';
    notifyListeners();
  }

  Future<bool> suspendSelectedUser(String reason) async {
    final userId = _selectedUserId;

    if (userId == null) {
      _errorMessage = 'Please select a user';
      notifyListeners();
      return false;
    }

    final trimmedReason = reason.trim();

    if (trimmedReason.isEmpty) {
      _errorMessage = 'Please specify the reason for the account suspension.';
      notifyListeners();
      return false;
    }

    if (trimmedReason.length > 500) {
      _errorMessage = 'The reason must not exceed 500 characters.';
      notifyListeners();
      return false;
    }

    return _updateSuspension(
      userId: userId,
      isSuspended: true,
      reason: trimmedReason,
    );
  }

  Future<bool> activateSelectedUser() async {
    final userId = _selectedUserId;

    if (userId == null) {
      _errorMessage = 'Please select a user';
      notifyListeners();
      return false;
    }

    return _updateSuspension(userId: userId, isSuspended: false);
  }

  Future<bool> _updateSuspension({
    required String userId,
    required bool isSuspended,
    String? reason,
  }) async {
    try {
      final token = await _getToken();

      final body = <String, dynamic>{'is_suspended': isSuspended};

      if (isSuspended) {
        body['reason'] = reason;
      }

      final response = await http
          .patch(
            Uri.parse('$_baseUrl/api/users/$userId/suspension'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(_getErrorMessage(response));
      }

      _suspendedUsers[userId] = isSuspended;

      if (isSuspended && reason != null) {
        _suspensionReasons[userId] = reason;
      } else {
        _suspensionReasons.remove(userId);
      }

      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  void toggleSuspend(String userId, bool value) {
    if (value) {
      _selectedUserId = userId;
      notifyListeners();
    } else {
      _selectedUserId = userId;
      activateSelectedUser();
    }
  }

  UserHistoryUser _createUser(Map<String, dynamic> data) {
    final id = _firstValue(data, ['id', 'user_id'])?.toString() ?? '';

    final name =
        _firstValue(data, [
          'name',
          'username',
          'full_name',
          'display_name',
        ])?.toString() ??
        'Unknown User';

    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : data;

    return UserHistoryUser(
      id: id,
      name: name,
      initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
      total: _toInt(
        _firstValue(summary, [
          'total',
          'total_transactions',
          'total_borrows',
          'total_activities',
          'total_records',
        ]),
      ),
      lending: _toInt(
        _firstValue(summary, [
          'lending',
          'total_lending',
          'active_lending',
          'lending_count',
        ]),
      ),
      overdue: _toInt(
        _firstValue(summary, ['overdue', 'overdue_count', 'total_overdue']),
      ),
      activities: [],
    );
  }

  UserHistoryActivity _createActivity(Map<String, dynamic> data) {
    final rawCategory =
        _firstValue(data, [
          'category',
          'type',
          'transaction_type',
        ])?.toString() ??
        'Other';

    final lowerCategory = rawCategory.toLowerCase();

    String category;

    if (lowerCategory.contains('rental') ||
        lowerCategory.contains('borrow') ||
        lowerCategory.contains('lend') ||
        lowerCategory.contains('rent')) {
      category = 'Rental';
    } else if (lowerCategory.contains('finance') ||
        lowerCategory.contains('payment') ||
        lowerCategory.contains('wallet') ||
        lowerCategory.contains('deposit')) {
      category = 'Finance';
    } else {
      category = 'Other';
    }

    return UserHistoryActivity(
      date:
          _firstValue(data, ['date', 'created_at', 'timestamp'])?.toString() ??
          '-',
      category: category,
      title:
          _firstValue(data, [
            'title',
            'description',
            'message',
            'action',
            'activity',
          ])?.toString() ??
          '-',
      performedBy:
          _firstValue(data, [
            'performed_by',
            'actor',
            'actor_username',
            'username',
            'user_name',
          ])?.toString() ??
          '-',
    );
  }

  Future<String> _getToken() async {
    final token = await _authService.loadToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token not found. Please log in again.');
    }

    return token;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  dynamic _firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data[key] != null) return data[key];
    }
    return null;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;

    final text = value?.toString().toLowerCase();

    return text == 'true' || text == '1';
  }

  String _getErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return decoded['message']?.toString() ??
            'An error occurred. (${response.statusCode})';
      }
    } catch (_) {}

    return 'An error occurred. (${response.statusCode})';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

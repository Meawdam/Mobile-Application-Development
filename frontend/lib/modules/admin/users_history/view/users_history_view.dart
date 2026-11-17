import 'package:flutter/material.dart';
//import 'controller/users_history_controller.dart';
//import 'model/user_history_model.dart';
import 'package:frontend/modules/admin/users_history/controller/users_history_controller.dart';
import 'package:frontend/modules/admin/users_history/model/user_history_model.dart';
import '../../admin_time.dart';

class UsersHistoryPage extends StatefulWidget {
  const UsersHistoryPage({super.key});

  @override
  State<UsersHistoryPage> createState() => _UsersHistoryPageState();
}

class _UsersHistoryPageState extends State<UsersHistoryPage> {
  static const _pageBg = Color(0xFFF4F7FC);
  static const _navy = Color(0xFF172554);
  // Team palette (agreed colors only). Do not add new colors without
  // sending the code to the team first.
  static const _blue = Color(0xFF2F4BFF);
  static const _red = Color.fromARGB(255, 223, 42, 42);
  static const _yellow = Color.fromARGB(255, 252, 252, 75);
  static const _green = Color.fromARGB(255, 72, 230, 83);
  // Text on yellow/green needs to be dark to stay readable.
  static const _onLight = Color(0xFF172554);
  static const _blueTint = Color(0xFFE8ECFF);
  static const _redTint = Color(0xFFFCE8E8);

  late final UsersHistoryController controller;
  final TextEditingController userSearchController = TextEditingController();
  final TextEditingController activitySearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = UsersHistoryController();
    controller.addListener(_refresh);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      await controller.fetchUsers();
    } catch (_) {
      // The controller stores the message for display in the page.
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    userSearchController.dispose();
    activitySearchController.dispose();
    super.dispose();
  }

  void _selectUser(UserHistoryUser user) {
    controller.selectUser(user.id);
    controller.searchUsers('');
    userSearchController.clear();
    activitySearchController.clear();
  }

  void _toggleSuspend() {
    if (controller.isSelectedUserSuspended) {
      _showActivateDialog();
    } else {
      _showSuspendDialog();
    }
  }

  void _showSuspendDialog() {
    final user = controller.selectedUser;
    final reasonController = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Suspend account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suspend ${user.name}? The user will not be able to use the app until re-activated.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                maxLines: 3,
                autofocus: true,
                onChanged: (_) {
                  if (errorText != null) setDialogState(() => errorText = null);
                },
                decoration: InputDecoration(
                  labelText: 'Reason for suspension (required)',
                  hintText: 'Enter the reason...',
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();

                if (reason.isEmpty) {
                  setDialogState(() => errorText = 'Please enter a reason');
                  return;
                }

                final success = await controller.suspendSelectedUser(reason);

                if (!mounted || !dialogContext.mounted) return;

                if (!success) {
                  setDialogState(() {
                    errorText =
                        controller.errorMessage ?? 'Unable to suspend account';
                  });
                  return;
                }

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Account suspended')),
                );
              },
              child: const Text('Suspend'),
            ),
          ],
        ),
      ),
    ).whenComplete(reasonController.dispose);
  }

  void _showActivateDialog() {
    final user = controller.selectedUser;
    final reason = controller.selectedUserSuspensionReason;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Activate account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Allow ${user.name} to use the app again?'),
            if (reason != null) ...[
              const SizedBox(height: 14),
              const Text(
                'Suspension reason',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _redTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(reason, style: const TextStyle(color: _onLight)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _onLight,
            ),
            onPressed: () {
              controller.activateSelectedUser();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account activated')),
              );
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    controller.resetFilters();
    activitySearchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.selectedUser;
        final suspended = controller.isSelectedUserSuspended;
        final activities = controller.filteredActivities;

        return Container(
          color: _pageBg,
          child: SafeArea(
            top: false,
            child: controller.isLoadingUsers && controller.users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : controller.errorMessage != null && controller.users.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 620;
                      final horizontal = compact ? 16.0 : 28.0;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          22,
                          horizontal,
                          30,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Users & History',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: _navy,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Manage user accounts and review their activity records',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blueGrey.shade600,
                                  ),
                                ),
                                if (controller.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    controller.errorMessage!,
                                    style: const TextStyle(color: _red),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                _sectionLabel('USER DIRECTORY'),
                                const SizedBox(height: 9),
                                _userSearchField(),
                                const SizedBox(height: 10),
                                _userSelector(user),
                                const SizedBox(height: 18),
                                _profileCard(user, suspended, compact),
                                const SizedBox(height: 22),
                                _activityPanel(activities, compact),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 1.5,
      color: Color(0xFF64748B),
      fontWeight: FontWeight.w800,
    ),
  );

  void _onUserSearch(String value) {
    controller.searchUsers(value);
    final matches = controller.filteredUsers;
    if (value.trim().isNotEmpty &&
        matches.isNotEmpty &&
        matches.first.id != controller.selectedUserId) {
      controller.selectUser(matches.first.id);
      activitySearchController.clear();
    }
  }

  Widget _userSearchField() {
    final query = userSearchController.text.trim();
    final matches = controller.filteredUsers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: userSearchController,
          onChanged: _onUserSearch,
          textInputAction: TextInputAction.search,
          onSubmitted: _onUserSearch,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Search users by name...',
            prefixIcon: const Icon(Icons.search_rounded, color: _blue),
            suffixIcon: userSearchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      userSearchController.clear();
                      controller.searchUsers('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDCE5F2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _blue, width: 1.6),
            ),
          ),
        ),
        if (query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              matches.isEmpty
                  ? 'No users found'
                  : matches.length == 1
                  ? 'Showing ${matches.first.name}'
                  : '${matches.length} matches - showing ${matches.first.name}. Tap the name below to see all users.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: matches.isEmpty ? _red : const Color(0xFF64748B),
              ),
            ),
          ),
      ],
    );
  }

  Widget _userSelector(UserHistoryUser selectedUser) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openUserPicker,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 13, 14, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE5F2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF172554).withOpacity(0.045),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: _blueTint,
                child: Text(
                  selectedUser.initial,
                  style: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TAP TO CHOOSE USER',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.1,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedUser.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _blue,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUserPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _userPickerSheet(sheetContext),
      ),
    );
  }

  Widget _userPickerSheet(BuildContext sheetContext) {
    final users = controller.users;
    final selectedId = controller.selectedUser.id;
    final grouped = <String, List<UserHistoryUser>>{};
    for (final user in users) {
      final key = user.name.isEmpty ? '#' : user.name[0].toUpperCase();
      grouped.putIfAbsent(key, () => []).add(user);
    }
    final groupKeys = grouped.keys.toList()..sort();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(sheetContext).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'All users',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE8EDF5)),
            Expanded(
              child: users.isEmpty
                  ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                      children: [
                        for (final letter in groupKeys) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                            child: Text(
                              letter,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _blue,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          for (final person in grouped[letter]!)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                color: person.id == selectedId
                                    ? _blueTint
                                    : const Color(0xFFF7F9FD),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    _selectUser(person);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 17,
                                          backgroundColor: const Color(
                                            0xFFEAF0F8,
                                          ),
                                          child: Text(
                                            person.initial,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _navy,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Text(
                                            person.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: _navy,
                                            ),
                                          ),
                                        ),
                                        if (person.id == selectedId)
                                          const Icon(
                                            Icons.check_circle,
                                            color: _blue,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(UserHistoryUser user, bool suspended, bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5F2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172554).withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: compact ? 27 : 32,
                backgroundColor: const Color(0xFFE8F0FF),
                child: Text(
                  user.initial,
                  style: TextStyle(
                    fontSize: compact ? 22 : 26,
                    color: _blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 18 : 21,
                        color: _navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: suspended ? _red : _green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          suspended ? 'Suspended account' : 'Active account',
                          style: TextStyle(
                            fontSize: 12,
                            color: suspended ? _red : const Color(0xFF1F9D2B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (suspended && controller.selectedUserSuspensionReason != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _redTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _red.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SUSPENSION REASON',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: _red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.selectedUserSuspensionReason!,
                    style: const TextStyle(fontSize: 13, color: _onLight),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 19),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 20) / 3;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statCard(
                    'ALL RECORDS',
                    user.total.toString(),
                    _blue,
                    Colors.white,
                    cardWidth,
                  ),
                  _statCard(
                    'LENDING',
                    user.lending.toString(),
                    _green,
                    _onLight,
                    cardWidth,
                  ),
                  _statCard(
                    'OVERDUE',
                    user.overdue.toString(),
                    _red,
                    Colors.white,
                    cardWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _toggleSuspend,
              icon: Icon(
                suspended ? Icons.check_circle_outline : Icons.block,
                size: 18,
              ),
              label: Text(suspended ? 'Activate Account' : 'Suspend Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: suspended ? const Color(0xFF1F9D2B) : _red,
                side: BorderSide(color: suspended ? _green : _red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color bg,
    Color fg,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: .5,
                color: fg,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                color: fg,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityPanel(List<UserHistoryActivity> activities, bool compact) {
    final selected = controller.selectedFilter;
    final showRoleFilters =
        selected == 'Rental' || selected == 'Lender' || selected == 'Borrower';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 15 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5F2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172554).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Activity Log',
                  style: TextStyle(
                    fontSize: 21,
                    color: _navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${activities.length} records',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip('All', const Color(0xFF64748B)),
              _filterChip('Rental', _blue),
              _filterChip('Finance', _yellow),
            ],
          ),
          if (showRoleFilters) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'RENTAL ROLE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 9),
                _filterChip('Lender', _blue, compact: true),
                const SizedBox(width: 7),
                _filterChip('Borrower', _green, compact: true),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: activitySearchController,
            onChanged: controller.searchActivities,
            decoration: InputDecoration(
              hintText: 'Search activity, category or performer...',
              prefixIcon: const Icon(Icons.search_rounded, color: _blue),
              suffixIcon: activitySearchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        activitySearchController.clear();
                        controller.searchActivities('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF4F7FC),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt, size: 17),
              label: const Text('Reset filters'),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF5)),
          const SizedBox(height: 13),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 35,
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No activity found',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activities.map(_activityCard),
        ],
      ),
    );
  }

  bool _isLight(Color c) => c == _yellow || c == _green;

  Widget _filterChip(String filter, Color accent, {bool compact = false}) {
    final selected = controller.selectedFilter == filter;
    final onAccent = _isLight(accent) ? _onLight : Colors.white;
    return ChoiceChip(
      label: Text(
        filter,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w800,
          color: selected ? onAccent : (_isLight(accent) ? _onLight : accent),
        ),
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => controller.setFilter(filter),
      selectedColor: accent,
      backgroundColor: accent.withOpacity(_isLight(accent) ? 0.55 : 0.15),
      side: BorderSide(
        color: accent.withOpacity(selected ? 0 : 0.9),
        width: 1.4,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 7,
        vertical: compact ? 0 : 2,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _activityCard(UserHistoryActivity activity) {
    final finance = activity.category == 'Finance';
    final role = controller.rentalRole(activity);
    final accent = finance
        ? _yellow
        : role == 'Lender'
        ? _blue
        : _green;
    final onAccent = _isLight(accent) ? _onLight : Colors.white;
    const edge = BorderSide(color: Color(0xFFE2E8F2));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFF),
            border: Border(
              left: BorderSide(color: accent, width: 8),
              top: edge,
              right: edge,
              bottom: edge,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 7,
                children: [
                  Text(
                    formatAdminTime(activity.date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      finance ? 'FINANCE' : 'RENTAL',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: .7,
                        color: onAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 15,
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 15,
                    color: Colors.blueGrey.shade400,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Performed by: ${activity.performedBy}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  if (role.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 10,
                          color: onAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'controller/users_history_controller.dart';
import 'model/user_history_model.dart';

class UsersHistoryPage extends StatefulWidget {
  const UsersHistoryPage({super.key});

  @override
  State<UsersHistoryPage> createState() => _UsersHistoryPageState();
}

class _UsersHistoryPageState extends State<UsersHistoryPage> {
  final Color backgroundColor = const Color(0xFFF2EFF3);
  final Color primaryColor = const Color(0xFF2100B5);

  late final UsersHistoryController controller;

  bool isUserDropdownExpanded = false;

  final TextEditingController userSearchController =
      TextEditingController();

  final FocusNode userSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = UsersHistoryController();
  }

  @override
  void dispose() {
    controller.dispose();
    userSearchController.dispose();
    userSearchFocusNode.dispose();
    super.dispose();
  }

  // Select another user.
  void selectUser(UserHistoryUser user) {
    controller.selectUser(user.id);
    controller.searchUsers('');

    userSearchController.clear();
    userSearchFocusNode.unfocus();

    setState(() {
      isUserDropdownExpanded = false;
    });
  }

  // Open or close dropdown.
  void toggleUserDropdown() {
    setState(() {
      isUserDropdownExpanded = !isUserDropdownExpanded;
    });
  }

  // Suspend or activate account.
  void toggleSuspend() {
    final user = controller.selectedUser;
    final isSuspended = controller.isSelectedUserSuspended;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isSuspended ? 'Activate Account?' : 'Suspend Account?',
          ),
          content: Text(
            isSuspended
                ? 'Do you want to activate ${user.name}?'
                : 'Do you want to suspend ${user.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.toggleSuspend();

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isSuspended
                          ? 'Account activated'
                          : 'Account suspended',
                    ),
                  ),
                );
              },
              child: Text(
                isSuspended ? 'Activate' : 'Suspend',
              ),
            ),
          ],
        );
      },
    );
  }

  // Reset activity filters.
  void resetFilters() {
    controller.resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final user = controller.selectedUser;
        final isSuspended = controller.isSelectedUserSuspended;
        final filteredUsers = controller.filteredUsers;
        final filteredActivities = controller.filteredActivities;

        return Container(
          color: backgroundColor,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page heading.
                  const Text(
                    'Users & History',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF252329),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'View activity logs for each user',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Select User',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // User dropdown and search.
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Selected user.
                        InkWell(
                          onTap: toggleUserDropdown,
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 19,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Text(
                                    user.initial,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isUserDropdownExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: primaryColor,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // One search field - always visible.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            12,
                          ),
                          child: TextField(
                            controller: userSearchController,
                            focusNode: userSearchFocusNode,
                            onTap: () {
                              setState(() {
                                isUserDropdownExpanded = true;
                              });
                            },
                            onChanged: (value) {
                              controller.searchUsers(value);

                              setState(() {
                                isUserDropdownExpanded = true;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search user by name...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon:
                                  userSearchController.text.isNotEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            userSearchController.clear();
                                            controller.searchUsers('');

                                            setState(() {
                                              isUserDropdownExpanded = true;
                                            });

                                            userSearchFocusNode.requestFocus();
                                          },
                                          icon: const Icon(Icons.close),
                                        )
                                      : null,
                              filled: true,
                              fillColor: const Color(0xFFF3F1F5),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        // Search results.
                        if (isUserDropdownExpanded) ...[
                          Divider(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),

                          if (filteredUsers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(18),
                              child: Center(
                                child: Text(
                                  'No users found',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...filteredUsers.map((listedUser) {
                              final isSelected =
                                  listedUser.id == user.id;

                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () => selectUser(listedUser),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 19,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            child: Text(
                                              listedUser.initial,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              listedUser.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                          else
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (listedUser != filteredUsers.last)
                                    Divider(
                                      height: 1,
                                      color: Colors.grey.shade200,
                                      indent: 15,
                                      endIndent: 15,
                                    ),
                                ],
                              );
                            }),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // User profile.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F3FA),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.grey.shade300,
                              child: Text(
                                user.initial,
                                style: const TextStyle(
                                  fontSize: 27,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    isSuspended
                                        ? 'Account suspended'
                                        : 'Active account',
                                    style: TextStyle(
                                      color: isSuspended
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        Row(
                          children: [
                            _statCard(
                              'All Records',
                              user.total.toString(),
                              const Color(0xFFEEEEEE),
                            ),
                            const SizedBox(width: 8),
                            _statCard(
                              'Lending',
                              user.lending.toString(),
                              const Color(0xFFEEEEEE),
                            ),
                            const SizedBox(width: 8),
                            _statCard(
                              'Overdue',
                              user.overdue.toString(),
                              const Color(0xFFFFCDD2),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: toggleSuspend,
                            icon: Icon(
                              isSuspended
                                  ? Icons.check_circle_outline
                                  : Icons.block,
                              color: isSuspended
                                  ? Colors.green
                                  : Colors.red,
                              size: 19,
                            ),
                            label: Text(
                              isSuspended
                                  ? 'Activate Account'
                                  : 'Suspend Account',
                              style: TextStyle(
                                color: isSuspended
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 15,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.grey.shade500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Activity Log.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F3FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Log',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _filterChip('All'),
                            _filterChip('Rental'),
                            _filterChip('Finance'),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: resetFilters,
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFF7655B5),
                            ),
                            label: const Text(
                              'Reset filters',
                              style: TextStyle(
                                color: Color(0xFF7655B5),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const Divider(),
                        const SizedBox(height: 8),

                        if (filteredActivities.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(25),
                            child: Center(
                              child: Text(
                                'No activity found',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          ...filteredActivities.map(
                            (activity) => _activityCard(activity),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Statistics card.
  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Activity filter buttons.
  Widget _filterChip(String filter) {
    final selected = controller.selectedFilter == filter;

    return ChoiceChip(
      label: Text(filter),
      selected: selected,
      showCheckmark: selected,
      onSelected: (_) {
        controller.setFilter(filter);
      },
      selectedColor: const Color(0xFFE9DDF8),
      backgroundColor: const Color(0xFFF8F3FA),
      labelStyle: TextStyle(
        color: selected
            ? const Color(0xFF51416B)
            : const Color(0xFF514B57),
      ),
      side: BorderSide(
        color: selected
            ? const Color(0xFFE9DDF8)
            : Colors.grey.shade400,
      ),
    );
  }

  // Activity record card.
  Widget _activityCard(UserHistoryActivity activity) {
    final isFinance = activity.category == 'Finance';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  activity.date,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isFinance
                      ? const Color(0xFFE1F1E4)
                      : const Color(0xFFE0EDFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activity.category,
                  style: TextStyle(
                    color: isFinance ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            activity.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Performed by: ${activity.performedBy}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}


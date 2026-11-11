import 'package:flutter/material.dart';

class UsersHistoryPage extends StatefulWidget {
  const UsersHistoryPage({super.key});

  @override
  State<UsersHistoryPage> createState() => _UsersHistoryPageState();
}

class _UsersHistoryPageState extends State<UsersHistoryPage> {
  final Color backgroundColor = const Color(0xFFF2EFF3);
  final Color primaryColor = const Color(0xFF2100B5);

  String selectedUserId = 'user1';
  String selectedFilter = 'All';
  String userSearch = '';

  bool isUserDropdownExpanded = false;

  final TextEditingController userSearchController = TextEditingController();

  final FocusNode userSearchFocusNode = FocusNode();

  final Set<String> suspendedUsers = {};

  // Sample users - connect to Backend later.
  final List<Map<String, dynamic>> users = [
    {
      'id': 'user1',
      'name': 'Somchai J.',
      'initial': 'S',
      'total': 10,
      'lending': 6,
      'overdue': 1,
      'activities': [
        {
          'date': '30 Oct. 11:12',
          'category': 'Finance',
          'title': 'Payment successful 245à¸¿',
          'performedBy': 'User',
        },
        {
          'date': '29 Oct. 14:30',
          'category': 'Rental',
          'title': 'Borrowed Lab Equipment',
          'performedBy': 'User',
        },
        {
          'date': '28 Oct. 09:15',
          'category': 'Rental',
          'title': 'Item returned successfully',
          'performedBy': 'User',
        },
        {
          'date': '27 Oct. 16:20',
          'category': 'Finance',
          'title': 'Late fee payment 50à¸¿',
          'performedBy': 'User',
        },
      ],
    },
    {
      'id': 'user2',
      'name': 'Suphaporn K.',
      'initial': 'S',
      'total': 8,
      'lending': 4,
      'overdue': 0,
      'activities': [
        {
          'date': '30 Oct. 10:30',
          'category': 'Rental',
          'title': 'Borrowed Calculator',
          'performedBy': 'User',
        },
        {
          'date': '29 Oct. 13:45',
          'category': 'Finance',
          'title': 'Payment successful 120à¸¿',
          'performedBy': 'User',
        },
        {
          'date': '27 Oct. 11:00',
          'category': 'Rental',
          'title': 'Item returned successfully',
          'performedBy': 'User',
        },
      ],
    },
    {
      'id': 'user3',
      'name': 'Nattapat P.',
      'initial': 'N',
      'total': 12,
      'lending': 7,
      'overdue': 2,
      'activities': [
        {
          'date': '30 Oct. 15:20',
          'category': 'Finance',
          'title': 'Payment successful 300à¸¿',
          'performedBy': 'User',
        },
        {
          'date': '29 Oct. 09:10',
          'category': 'Rental',
          'title': 'Borrowed Textbook',
          'performedBy': 'User',
        },
        {
          'date': '28 Oct. 14:00',
          'category': 'Rental',
          'title': 'Overdue item recorded',
          'performedBy': 'System',
        },
      ],
    },
  ];

  Map<String, dynamic> get selectedUser {
    return users.firstWhere((user) => user['id'] == selectedUserId);
  }

  // Search users by any part of their name.
  List<Map<String, dynamic>> get filteredUsers {
    final query = userSearch.trim().toLowerCase();

    return users.where((user) {
      return user['name'].toString().toLowerCase().contains(query);
    }).toList();
  }

  // Filter activities by All, Rental, or Finance.
  List<Map<String, dynamic>> get filteredActivities {
    final activities = List<Map<String, dynamic>>.from(
      selectedUser['activities'],
    );

    return activities.where((activity) {
      return selectedFilter == 'All' || activity['category'] == selectedFilter;
    }).toList();
  }

  @override
  void dispose() {
    userSearchController.dispose();
    userSearchFocusNode.dispose();
    super.dispose();
  }

  // Open or close user dropdown.
  void toggleUserDropdown() {
    setState(() {
      isUserDropdownExpanded = !isUserDropdownExpanded;
    });
  }

  // Select another user.
  void selectUser(Map<String, dynamic> user) {
    setState(() {
      selectedUserId = user['id'];
      selectedFilter = 'All';

      userSearch = '';
      userSearchController.clear();

      isUserDropdownExpanded = false;
    });

    userSearchFocusNode.unfocus();
  }

  // Reset activity filters.
  void resetFilters() {
    setState(() {
      selectedFilter = 'All';
    });
  }

  // Suspend or activate account.
  void toggleSuspend() {
    final name = selectedUser['name'];
    final isSuspended = suspendedUsers.contains(selectedUserId);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isSuspended ? 'Activate Account?' : 'Suspend Account?'),
          content: Text(
            isSuspended
                ? 'Do you want to activate $name?'
                : 'Do you want to suspend $name?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isSuspended) {
                    suspendedUsers.remove(selectedUserId);
                  } else {
                    suspendedUsers.add(selectedUserId);
                  }
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isSuspended ? 'Account activated' : 'Account suspended',
                    ),
                  ),
                );
              },
              child: Text(isSuspended ? 'Activate' : 'Suspend'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = selectedUser;
    final isSuspended = suspendedUsers.contains(selectedUserId);

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
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 20),

              const Text(
                'Select User',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              // User dropdown and one search field.
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selected user and dropdown arrow.
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
                                user['initial'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user['name'],
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

                    // User search - always visible.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: TextField(
                        controller: userSearchController,
                        focusNode: userSearchFocusNode,
                        onTap: () {
                          setState(() {
                            isUserDropdownExpanded = true;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            userSearch = value;
                            isUserDropdownExpanded = true;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search user by name...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: userSearch.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      userSearch = '';
                                      userSearchController.clear();
                                      isUserDropdownExpanded = true;
                                    });
                                    userSearchFocusNode.requestFocus();
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF3F1F5),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // User results appear when searching or opening dropdown.
                    if (isUserDropdownExpanded) ...[
                      Divider(height: 1, color: Colors.grey.shade300),

                      if (filteredUsers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(18),
                          child: Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...filteredUsers.map((listedUser) {
                          final isSelected = listedUser['id'] == selectedUserId;

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
                                        backgroundColor: Colors.grey.shade200,
                                        child: Text(
                                          listedUser['initial'],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          listedUser['name'],
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
                            user['initial'],
                            style: const TextStyle(
                              fontSize: 27,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'],
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
                          user['total'].toString(),
                          const Color(0xFFEEEEEE),
                        ),
                        const SizedBox(width: 8),
                        _statCard(
                          'Lending',
                          user['lending'].toString(),
                          const Color(0xFFEEEEEE),
                        ),
                        const SizedBox(width: 8),
                        _statCard(
                          'Overdue',
                          user['overdue'].toString(),
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
                          color: isSuspended ? Colors.green : Colors.red,
                          size: 19,
                        ),
                        label: Text(
                          isSuspended ? 'Activate Account' : 'Suspend Account',
                          style: TextStyle(
                            color: isSuspended ? Colors.green : Colors.red,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade500),
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
                            style: TextStyle(color: Colors.grey),
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
  }

  // Statistics card.
  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Activity filter buttons.
  Widget _filterChip(String filter) {
    final selected = selectedFilter == filter;

    return ChoiceChip(
      label: Text(filter),
      selected: selected,
      showCheckmark: selected,
      onSelected: (_) {
        setState(() {
          selectedFilter = filter;
        });
      },
      selectedColor: const Color(0xFFE9DDF8),
      backgroundColor: const Color(0xFFF8F3FA),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF51416B) : const Color(0xFF514B57),
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFE9DDF8) : Colors.grey.shade400,
      ),
    );
  }

  // Activity record card.
  Widget _activityCard(Map<String, dynamic> activity) {
    final isFinance = activity['category'] == 'Finance';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  activity['date'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                  activity['category'],
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
            activity['title'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          Text(
            'Performed by: ${activity['performedBy']}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

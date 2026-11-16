class UserHistoryActivity {
  final String date;
  final String category;
  final String title;
  final String performedBy;
  final String? rentalRole;

  const UserHistoryActivity({
    required this.date,
    required this.category,
    required this.title,
    required this.performedBy,
    this.rentalRole,
  });

  factory UserHistoryActivity.fromMap(Map<String, dynamic> map) {
    return UserHistoryActivity(
      date: map['date']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      performedBy: map['performedBy']?.toString() ?? '',
      rentalRole: map['rentalRole']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'category': category,
      'title': title,
      'performedBy': performedBy,
      'rentalRole': rentalRole,
    };
  }
}

class UserHistoryUser {
  final String id;
  final String name;
  final String initial;
  final int total;
  final int lending;
  final int overdue;
  final List<UserHistoryActivity> activities;

  const UserHistoryUser({
    required this.id,
    required this.name,
    required this.initial,
    required this.total,
    required this.lending,
    required this.overdue,
    required this.activities,
  });

  factory UserHistoryUser.fromMap(Map<String, dynamic> map) {
    final rawActivities = map['activities'] as List? ?? [];

    final activities = rawActivities
        .whereType<Map>()
        .map(
          (activity) => UserHistoryActivity.fromMap(
            Map<String, dynamic>.from(activity),
          ),
        )
        .toList();

    return UserHistoryUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      initial: map['initial']?.toString() ?? '',
      total: (map['total'] as num?)?.toInt() ?? 0,
      lending: (map['lending'] as num?)?.toInt() ?? 0,
      overdue: (map['overdue'] as num?)?.toInt() ?? 0,
      activities: activities,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial': initial,
      'total': total,
      'lending': lending,
      'overdue': overdue,
      'activities': activities.map((activity) => activity.toMap()).toList(),
    };
  }
}
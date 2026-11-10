
class ApproveItem {
  final String id;
  final String name;
  final String owner;
  final String time;
  final String category;
  final String description;

  const ApproveItem({
    required this.id,
    required this.name,
    required this.owner,
    required this.time,
    required this.category,
    required this.description,
  });

  factory ApproveItem.fromMap(Map<String, dynamic> map) {
    return ApproveItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner': owner,
      'time': time,
      'category': category,
      'description': description,
    };
  }
}

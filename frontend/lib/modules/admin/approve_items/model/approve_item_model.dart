class ApproveItem {
  final String id;
  final String name;
  final String owner;
  final String time;
  final String description;
  final String imageUrl;

  const ApproveItem({
    required this.id,
    required this.name,
    required this.owner,
    required this.time,
    required this.description,
    this.imageUrl = '',
  });

  factory ApproveItem.fromMap(Map<String, dynamic> map) {
    return ApproveItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? map['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner': owner,
      'time': time,
      'description': description,
      'image_url': imageUrl,
    };
  }
}

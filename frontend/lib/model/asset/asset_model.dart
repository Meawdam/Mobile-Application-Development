class AssetModel {
  final int id;
  final int ownerId;
  final String? ownerUsername;
  final String? image;
  final String name;
  final String description;
  final String status;
  final String approval;
  final String? approvalMessage;
  final num downPayment;
  final String returnBefore;
  final int price;
  final String pickupPoint;

  const AssetModel({
    required this.id,
    required this.ownerId,
    this.ownerUsername,
    this.image,
    required this.name,
    required this.description,
    required this.status,
    required this.approval,
    this.approvalMessage,
    required this.downPayment,
    required this.returnBefore,
    required this.price,
    required this.pickupPoint,
  });

  String get imageUrl => image ?? '';

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: _asInt(json['id']),
      ownerId: _asInt(json['owner_id']),
      ownerUsername: json['owner_username']?.toString(),
      image: json['image']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      approval: json['approval']?.toString() ?? '',
      approvalMessage: json['approval_message']?.toString(),
      downPayment: _asNum(json['down_payment']),
      returnBefore: _formatDate(json['return_before']),
      price: _asInt(json['price']),
      pickupPoint: json['pickup_point']?.toString() ?? '',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '';
    final raw = value.toString();
    if (raw.length >= 10) {
      return raw.substring(0, 10);
    }
    return raw;
  }
}

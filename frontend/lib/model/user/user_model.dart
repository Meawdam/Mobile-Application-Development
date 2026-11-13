class UserModel {
  final int? id;
  final String username;
  final String phoneNumber;
  final String email;
  final String? password;
  final String role;

  const UserModel({
    this.id,
    required this.username,
    required this.phoneNumber,
    required this.email,
    this.password,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _asIntOrNull(json['id']),
      username: json['username']?.toString() ?? '',
      phoneNumber:
          (json['phone_num'] ?? json['phone_number'])?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString(),
      role: json['role']?.toString() ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'phone_num': phoneNumber,
      'email': email,
      if (password != null) 'password': password,
      'role': role,
    };
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

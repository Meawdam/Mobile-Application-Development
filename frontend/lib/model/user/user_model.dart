class UserModel {
  final String username;
  final String phoneNumber;
  final String email;
  final String password;
  final String role;

  const UserModel({
    required this.username,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      password: json['password'],
      role: json['role'],
    );
  }
}

final List<UserModel> users = [
  UserModel(
    username: 'test_user',
    phoneNumber: '0800000001',
    email: 'user@example.com',
    password: 'user123',
    role: 'user',
  ),
  UserModel(
    username: 'test_admin',
    phoneNumber: '0800000002',
    email: 'admin@example.com',
    password: 'admin123',
    role: 'admin',
  ),
];

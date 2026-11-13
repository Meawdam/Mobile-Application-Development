class UserModel {
  final String username;
  final String phoneNumber;
  final String email;
  final String role;

  const UserModel({
    required this.username,
    required this.phoneNumber,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      phoneNumber: json['phone_num'],
      email: json['email'],
      role: json['role'],
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/user/user_model.dart';

void main() {
  test('fromJson maps phone_num and defaults role to user', () {
    final user = UserModel.fromJson({
      'id': 5,
      'username': 'mike',
      'phone_num': '0812345678',
      'email': 'mike@example.com',
    });

    expect(user.id, 5);
    expect(user.phoneNumber, '0812345678');
    expect(user.role, 'user');
  });

  test('fromJson accepts phone_number alias', () {
    final user = UserModel.fromJson({
      'username': 'ann',
      'phone_number': '0899999999',
      'email': 'ann@example.com',
      'role': 'admin',
    });

    expect(user.phoneNumber, '0899999999');
    expect(user.role, 'admin');
  });

  test('toJson writes phone_num for the backend', () {
    const user = UserModel(
      id: 1,
      username: 'mike',
      phoneNumber: '0811111111',
      email: 'mike@example.com',
      password: 'secret123',
      role: 'user',
    );

    expect(user.toJson(), {
      'id': 1,
      'username': 'mike',
      'phone_num': '0811111111',
      'email': 'mike@example.com',
      'password': 'secret123',
      'role': 'user',
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/user/user_model.dart';
import 'package:frontend/modules/auth/login/controller/login_controller.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_api.dart';

class _FakeAuthApi extends AuthApi {
  @override
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final accounts = <String, ({String password, UserModel user})>{
      'user@example.com': (
        password: 'user123',
        user: const UserModel(
          id: 1,
          username: 'test_user',
          phoneNumber: '0800000001',
          email: 'user@example.com',
          role: 'user',
        ),
      ),
      'admin@example.com': (
        password: 'admin123',
        user: const UserModel(
          id: 2,
          username: 'test_admin',
          phoneNumber: '0800000002',
          email: 'admin@example.com',
          role: 'admin',
        ),
      ),
    };

    final account = accounts[email];
    if (account == null || account.password != password) {
      throw const ApiException(401, 'Invalid email or password');
    }

    return AuthLoginResult(token: 'test-token', user: account.user);
  }
}

void main() {
  test('1. returns the matching user account', () async {
    final controller = LoginController(authApi: _FakeAuthApi());
    final user = await controller.login('user@example.com', 'user123');

    expect(user, isNotNull);
    expect(user!.role, 'user');
  });

  test('2. returns the matching admin account', () async {
    final controller = LoginController(authApi: _FakeAuthApi());
    final user = await controller.login('admin@example.com', 'admin123');

    expect(user, isNotNull);
    expect(user!.role, 'admin');
  });

  test('3. matches email regardless of surrounding spaces or case', () async {
    final controller = LoginController(authApi: _FakeAuthApi());
    final user = await controller.login('  USER@EXAMPLE.COM  ', 'user123');

    expect(user, isNotNull);
    expect(user!.email, 'user@example.com');
  });

  test('4. returns null when the password is incorrect', () async {
    final controller = LoginController(authApi: _FakeAuthApi());
    expect(
      await controller.login('user@example.com', 'wrong-password'),
      isNull,
    );
  });

  test('5. returns null when the email is not registered', () async {
    final controller = LoginController(authApi: _FakeAuthApi());
    expect(await controller.login('unknown@example.com', 'user123'), isNull);
  });
}

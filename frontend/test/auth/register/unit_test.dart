import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/user/user_model.dart';
import 'package:frontend/modules/auth/register/controller/register_controller.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_api.dart';

class _FakeAuthApi extends AuthApi {
  final Set<String> existingEmails = {'user@example.com'};
  final Set<String> existingUsernames = {'test_user'};

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String phoneNum,
  }) async {
    if (existingEmails.contains(email.toLowerCase())) {
      throw const ApiException(400, 'Email is already taken');
    }
    if (existingUsernames.contains(username)) {
      throw const ApiException(400, 'Username is already taken');
    }

    existingEmails.add(email.toLowerCase());
    existingUsernames.add(username);
    return UserModel(
      id: 99,
      username: username,
      phoneNumber: phoneNum,
      email: email,
      role: 'user',
    );
  }
}

void main() {
  test('1. creates a user account successfully', () async {
    final controller = RegisterController(authApi: _FakeAuthApi());
    final result = await controller.register(
      username: ' Test User ',
      phoneNumber: ' 0800000003 ',
      email: ' REGISTER-CONTROLLER-TEST@example.com ',
      password: 'newuser123',
      confirmPassword: 'newuser123',
    );

    expect(result, RegisterResult.success);
  });

  test('2. rejects a registered email regardless of case', () async {
    final controller = RegisterController(authApi: _FakeAuthApi());
    final result = await controller.register(
      username: 'Another User',
      phoneNumber: '0800000004',
      email: ' USER@EXAMPLE.COM ',
      password: 'newuser123',
      confirmPassword: 'newuser123',
    );

    expect(result, RegisterResult.emailAlreadyExists);
  });

  test('3. rejects missing fields', () async {
    final controller = RegisterController(authApi: _FakeAuthApi());
    final result = await controller.register(
      username: 'New User',
      phoneNumber: '0800000005',
      email: 'register-controller-test@example.com',
      password: '',
      confirmPassword: '',
    );

    expect(result, RegisterResult.missingFields);
  });

  test('4. rejects passwords shorter than eight characters', () async {
    final controller = RegisterController(authApi: _FakeAuthApi());
    final result = await controller.register(
      username: 'New User',
      phoneNumber: '0800000005',
      email: 'register-controller-test@example.com',
      password: 'short',
      confirmPassword: 'short',
    );

    expect(result, RegisterResult.passwordTooShort);
  });

  test('5. rejects passwords that do not match', () async {
    final controller = RegisterController(authApi: _FakeAuthApi());
    final result = await controller.register(
      username: 'New User',
      phoneNumber: '0800000005',
      email: 'register-controller-test@example.com',
      password: 'newuser123',
      confirmPassword: 'different123',
    );

    expect(result, RegisterResult.passwordMismatch);
  });
}

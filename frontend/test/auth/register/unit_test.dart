import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/login/controller/login_controller.dart';
import 'package:frontend/modules/auth/register/controller/register_controller.dart';

const _testEmail = 'register-controller-test@example.com';

void main() {
  test('1. creates a user account that can log in', () {
    final controller = RegisterController();
    final result = controller.register(
      username: ' Test User ',
      phoneNumber: ' 0800000003 ',
      email: ' REGISTER-CONTROLLER-TEST@example.com ',
      password: 'newuser123',
      confirmPassword: 'newuser123',
    );

    expect(result, RegisterResult.success);
    final user = LoginController().login(_testEmail, 'newuser123');
    expect(user, isNotNull);
    expect(user!.username, 'Test User');
    expect(user.phoneNumber, '0800000003');
    expect(user.role, 'user');
  });

  test('2. rejects a registered email regardless of case', () {
    final controller = RegisterController();
    final result = controller.register(
      username: 'Another User',
      phoneNumber: '0800000004',
      email: ' USER@EXAMPLE.COM ',
      password: 'newuser123',
      confirmPassword: 'newuser123',
    );

    expect(result, RegisterResult.emailAlreadyExists);
  });

  test('3. rejects missing fields', () {
    final controller = RegisterController();
    final result = controller.register(
      username: 'New User',
      phoneNumber: '0800000005',
      email: _testEmail,
      password: '',
      confirmPassword: '',
    );

    expect(result, RegisterResult.missingFields);
  });

  test('4. rejects passwords shorter than eight characters', () {
    final controller = RegisterController();
    final result = controller.register(
      username: 'New User',
      phoneNumber: '0800000005',
      email: _testEmail,
      password: 'short',
      confirmPassword: 'short',
    );

    expect(result, RegisterResult.passwordTooShort);
  });

  test('5. rejects passwords that do not match', () {
    final controller = RegisterController();
    final result = controller.register(
      username: 'New User',
      phoneNumber: '0800000005',
      email: _testEmail,
      password: 'newuser123',
      confirmPassword: 'different123',
    );

    expect(result, RegisterResult.passwordMismatch);
  });
}

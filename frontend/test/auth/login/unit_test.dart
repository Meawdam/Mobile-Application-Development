import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/login/controller/login_controller.dart';

void main() {
  test('1. returns the matching user account', () {
    final controller = LoginController();
    final user = controller.login('user@example.com', 'user123');

    expect(user, isNotNull);
    expect(user!.role, 'user');
  });

  test('2. returns the matching admin account', () {
    final controller = LoginController();
    final user = controller.login('admin@example.com', 'admin123');

    expect(user, isNotNull);
    expect(user!.role, 'admin');
  });

  test('3. matches email regardless of surrounding spaces or case', () {
    final controller = LoginController();
    final user = controller.login('  USER@EXAMPLE.COM  ', 'user123');

    expect(user, isNotNull);
    expect(user!.email, 'user@example.com');
  });

  test('4. returns null when the password is incorrect', () {
    final controller = LoginController();
    expect(controller.login('user@example.com', 'wrong-password'), isNull);
  });

  test('5. returns null when the email is not registered', () {
    final controller = LoginController();
    expect(controller.login('unknown@example.com', 'user123'), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/login/controller/login_controller.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements Authservice;

void main() {
  test('1. Correct login should return user role', () async {
    final mockAuthService = MockAuthService();
    // mock method
    when(() => mockAuthService.saveToken(any())).thenAnswer((_) async {});

    // attach the mock auth service to the todo controller
    LoginController loginController = LoginController(service: mockAuthService);
    // TodoController todoController = TodoController();
    String? result = await loginController.login(
      'user@example.com',
      '12345678',
    );
    expect(result, isNotNull);
    expect(result, 'user');
    // admin
    result = await loginController.login('admin@example.com', '12345678');
    expect(result, 'admin');
  });

  test('2. Wrong login should return null', () async {
    LoginController loginController = LoginController();
    String? result = await loginController.login(
      'user@example.com',
      '11111111',
    );
    expect(result, isNull);
  });
}

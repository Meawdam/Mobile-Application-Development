import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/login/view/login_view.dart';
import 'package:frontend/modules/auth/register/controller/register_controller.dart';
import 'package:frontend/modules/auth/register/view/register_view.dart';
import 'package:mocktail/mocktail.dart';

class MockRegisterController extends Mock implements RegisterController {}

Widget _app(MockRegisterController controller) {
  return MaterialApp(
    home: const LoginScreen(),
    routes: {'/register': (_) => RegisterScreen(controller: controller)},
  );
}

Future<void> _openRegister(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create an account'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Register page should be shown with five text fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(MockRegisterController()));
    await _openRegister(tester);

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));
  });

  testWidgets('Incomplete input and register should show an error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(MockRegisterController()));
    await _openRegister(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.text('Please complete all fields'), findsOneWidget);
  });

  testWidgets('Wrong registration should show an error', (
    WidgetTester tester,
  ) async {
    final controller = MockRegisterController();
    when(() => controller.register(any(), any(), any(), any()))
        .thenAnswer((_) async => false);

    await tester.pumpWidget(_app(controller));
    await _openRegister(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextField).at(1), '0812345678');
    await tester.enterText(find.byType(TextField).at(2), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.enterText(find.byType(TextField).at(4), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to create account. Email or username may already be in use.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Correct registration should return to the login page', (
    WidgetTester tester,
  ) async {
    final controller = MockRegisterController();
    when(() => controller.register(any(), any(), any(), any()))
        .thenAnswer((_) async => true);

    await tester.pumpWidget(_app(controller));
    await _openRegister(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextField).at(1), '0812345678');
    await tester.enterText(find.byType(TextField).at(2), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.enterText(find.byType(TextField).at(4), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Account created. You can now log in.'), findsOneWidget);
  });
}

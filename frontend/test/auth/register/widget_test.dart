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

Future<void> _submitRegister(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Register');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
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
    await _submitRegister(tester);

    expect(find.byType(Dialog), findsOneWidget);
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
    await _submitRegister(tester);

    expect(find.byType(Dialog), findsOneWidget);
    expect(
      find.text(
        'Unable to create account. Email or username may already be in use.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Correct registration shows success popup then returns to login', (
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
    await _submitRegister(tester);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Account created'), findsOneWidget);
    expect(find.text('Your account is ready. You can now log in.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/login/controller/login_controller.dart';
import 'package:frontend/modules/auth/login/view/login_view.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginController extends Mock implements LoginController {}

void main() {
  testWidgets('Login page should be shown with two text fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: MockLoginController())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Empty input and login should show an error', (
    WidgetTester tester,
  ) async {
    final controller = MockLoginController();
    when(() => controller.login(any(), any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: controller)),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
  });

  testWidgets('Wrong login should show an error', (WidgetTester tester) async {
    final controller = MockLoginController();
    when(() => controller.login(any(), any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
  });

  testWidgets('Correct login as user should show the user page', (
    WidgetTester tester,
  ) async {
    final controller = MockLoginController();
    when(() => controller.login(any(), any())).thenAnswer((_) async => 'user');

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(controller: controller),
        routes: {'/home': (_) => const Scaffold(body: Text('User home'))},
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('User home'), findsOneWidget);
  });
}

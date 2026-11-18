import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/users_history/controller/users_history_controller.dart';
import 'package:frontend/modules/admin/users_history/view/users_history_view.dart';
import 'package:mocktail/mocktail.dart';

class MockUsersHistoryController extends Mock
    implements UsersHistoryController {}

void main() {
  testWidgets('Users and history page is displayed', (tester) async {
    final controller = MockUsersHistoryController();
    when(() => controller.isLoadingUsers).thenReturn(false);
    when(() => controller.users).thenReturn([]);
    when(() => controller.errorMessage).thenReturn('Unable to load users');
    when(() => controller.fetchUsers()).thenAnswer((_) async {});

    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: UsersHistoryPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UsersHistoryPage), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

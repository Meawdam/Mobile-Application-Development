import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/users_history/view/users_history_view.dart';

void main() {
  testWidgets('Users and history page is displayed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: UsersHistoryPage()));
    await tester.pumpAndSettle();

    expect(find.byType(UsersHistoryPage), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/admin/users_history/view/users_history_view.dart';


void main() {
  Future<void> pumpUsersHistoryPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));


    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UsersHistoryPage(),
        ),
      ),
    );


    await tester.pumpAndSettle();
  }


  final paymentText = find.textContaining('Payment successful');
  final lateFeeText = find.textContaining('Late fee payment');


  testWidgets('UsersHistoryPage renders correctly',
      (WidgetTester tester) async {
    await pumpUsersHistoryPage(tester);


    expect(find.text('Users & History'), findsOneWidget);
    expect(
      find.text('Manage user accounts and review their activity records'),
      findsOneWidget,
    );


    expect(find.text('USER DIRECTORY'), findsOneWidget);
    expect(find.text('Somchai J.'), findsWidgets);
    expect(find.text('TAP TO CHOOSE USER'), findsOneWidget);


    expect(find.text('Active account'), findsOneWidget);
    expect(find.text('ALL RECORDS'), findsOneWidget);
    expect(find.text('LENDING'), findsOneWidget);
    expect(find.text('OVERDUE'), findsOneWidget);


    expect(find.text('Activity Log'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Rental'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);


    expect(paymentText, findsOneWidget);
    expect(lateFeeText, findsOneWidget);
    expect(find.text('Borrowed Lab Equipment'), findsOneWidget);
    expect(find.text('Item returned successfully'), findsOneWidget);
  });


  testWidgets('Finance filter displays only finance activities',
      (WidgetTester tester) async {
    await pumpUsersHistoryPage(tester);


    await tester.tap(find.widgetWithText(ChoiceChip, 'Finance'));
    await tester.pumpAndSettle();


    expect(paymentText, findsOneWidget);
    expect(lateFeeText, findsOneWidget);


    expect(find.text('Borrowed Lab Equipment'), findsNothing);
    expect(find.text('Item returned successfully'), findsNothing);


    expect(find.text('2 records'), findsOneWidget);
  });


  testWidgets('Rental filter displays only rental activities',
      (WidgetTester tester) async {
    await pumpUsersHistoryPage(tester);


    await tester.tap(find.widgetWithText(ChoiceChip, 'Rental'));
    await tester.pumpAndSettle();


    expect(find.text('Borrowed Lab Equipment'), findsOneWidget);
    expect(find.text('Item returned successfully'), findsOneWidget);


    expect(paymentText, findsNothing);
    expect(lateFeeText, findsNothing);


    expect(find.text('2 records'), findsOneWidget);
  });


  testWidgets('Search filters activity logs',
      (WidgetTester tester) async {
    await pumpUsersHistoryPage(tester);


    final activitySearch = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText ==
              'Search activity, category or performer...',
    );


    await tester.enterText(activitySearch, 'successful');
    await tester.pumpAndSettle();


    expect(paymentText, findsOneWidget);
    expect(lateFeeText, findsNothing);
    expect(find.text('Borrowed Lab Equipment'), findsNothing);
  });


  testWidgets('Reset filters restores all activities',
      (WidgetTester tester) async {
    await pumpUsersHistoryPage(tester);


    final activitySearch = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText ==
              'Search activity, category or performer...',
    );


    await tester.tap(find.widgetWithText(ChoiceChip, 'Finance'));
    await tester.pumpAndSettle();


    await tester.enterText(activitySearch, 'Payment');
    await tester.pumpAndSettle();


    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();


    expect(find.text('4 records'), findsOneWidget);
    expect(paymentText, findsOneWidget);
    expect(lateFeeText, findsOneWidget);
    expect(find.text('Borrowed Lab Equipment'), findsOneWidget);
  });


  testWidgets('User selector allows selecting another user',
      (WidgetTester tester) async {
    await pumpUsersHistoryPage(tester);


    final selector = find.ancestor(
      of: find.text('TAP TO CHOOSE USER'),
      matching: find.byType(InkWell),
    );


    await tester.tap(selector.first);
    await tester.pumpAndSettle();


    expect(find.text('All users'), findsOneWidget);
    expect(find.text('Suphaporn K.'), findsOneWidget);
    expect(find.text('Nattapat P.'), findsOneWidget);


    await tester.tap(find.text('Suphaporn K.').last);
    await tester.pumpAndSettle();


    expect(find.text('Suphaporn K.'), findsWidgets);
    expect(find.text('Borrowed Calculator'), findsOneWidget);
    expect(find.textContaining('Payment successful 120'), findsOneWidget);
  });


  testWidgets('Suspend account requires a reason',
      (WidgetTester tester) async {
    await pumpUsersHistoryPage(tester);


    await tester.tap(find.text('Suspend Account'));
    await tester.pumpAndSettle();


    expect(find.text('Suspend account'), findsOneWidget);


    await tester.tap(find.text('Suspend').last);
    await tester.pumpAndSettle();


    expect(find.text('Please enter a reason'), findsOneWidget);
    expect(find.text('Active account'), findsOneWidget);
  });
}
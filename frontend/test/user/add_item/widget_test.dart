import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/add_item/controller/add_item_controller.dart';
import 'package:frontend/modules/user/add_item/view/add_item.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_helpers.dart';

// PNG ขนาด 1x1 พิกเซลที่ถูกต้อง (ใช้เป็นรูปที่ผู้ใช้เลือก)
final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

AddItemController _controller(MockHttpClient client) {
  final controller = AddItemController(
    client: client,
    authService: mockAuthservice(),
  );
  controller.setPickedImage(_tinyPng, 'camera.png');
  controller.setLendingEndDate(DateTime(2030, 1, 1));
  return controller;
}

Future<void> _fillForm(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Camera');
  await tester.enterText(fields.at(1), 'Digital camera');
  await tester.enterText(fields.at(2), '120');
  await tester.enterText(fields.at(3), '500');
  await tester.enterText(fields.at(4), 'Canteen');
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final button = find.text('Submit for Admin Approval');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerMockFallbacks);

  testWidgets('shows the form with five text fields and the submit button', (
    tester,
  ) async {
    useTallScreen(tester);
    final client = MockHttpClient();
    stubSend(client, jsonResponse({}, 201));

    await tester.pumpWidget(
      MaterialApp(home: AddItemScreen(controller: _controller(client))),
    );

    expect(find.text('Add Borrowing Item'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.text('Submit for Admin Approval'), findsOneWidget);
  });

  testWidgets('empty form shows a validation message and does not call the API', (
    tester,
  ) async {
    useTallScreen(tester);
    final client = MockHttpClient();
    stubSend(client, jsonResponse({}, 201));

    await tester.pumpWidget(
      MaterialApp(home: AddItemScreen(controller: _controller(client))),
    );
    await _tapSubmit(tester);

    expect(find.text('Please complete all fields'), findsOneWidget);
    verifyNever(() => client.send(any()));
  });

  testWidgets('valid form calls POST /api/assets, shows success and closes', (
    tester,
  ) async {
    useTallScreen(tester);
    final client = MockHttpClient();
    stubSend(
      client,
      jsonResponse({'message': 'Asset submitted for admin approval'}, 201),
    );

    await pumpPushed(tester, AddItemScreen(controller: _controller(client)));
    await _fillForm(tester);
    await _tapSubmit(tester);

    final request =
        verify(() => client.send(captureAny())).captured.single
            as http.MultipartRequest;
    expect(request.method, 'POST');
    expect(request.url, apiUri('/api/assets'));
    expect(request.headers['Authorization'], 'Bearer $testToken');
    expect(request.fields['name'], 'Camera');
    expect(request.files.single.field, 'image');
    expect(find.text('Item submitted for admin approval'), findsOneWidget);
    expect(find.byType(AddItemScreen), findsNothing);
  });

  testWidgets('backend error stays on the page and shows the message', (
    tester,
  ) async {
    useTallScreen(tester);
    final client = MockHttpClient();
    stubSend(client, jsonResponse({'message': 'Price must be positive'}, 400));

    await pumpPushed(tester, AddItemScreen(controller: _controller(client)));
    await _fillForm(tester);
    await _tapSubmit(tester);

    expect(find.text('Price must be positive'), findsOneWidget);
    expect(find.byType(AddItemScreen), findsOneWidget);
  });
}

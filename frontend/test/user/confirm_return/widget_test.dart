import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/requests_returns/view/requests_returns.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('owner confirms a return from the Requests & Returns screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => call.method == 'read' ? 'test-token' : null,
    );

    final requests = <http.Request>[];
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(home: RequestsReturnsScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Requests & Returns'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);

        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm returned item?'), findsOneWidget);
        await tester.tap(find.text('Confirm return'));
        await tester.pumpAndSettle();

        expect(find.text('Return confirmed'), findsOneWidget);
        expect(
          requests.map((request) => '${request.method} ${request.url.path}'),
          containsAllInOrder([
            'GET /api/borrows/owner',
            'PATCH /api/borrows/2/confirm-return',
            'GET /api/borrows/owner',
          ]),
        );
        final patch = requests.firstWhere(
          (request) => request.method == 'PATCH',
        );
        expect(patch.headers['Authorization'], 'Bearer test-token');
      },
      () => MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET' &&
            request.url.path == '/api/borrows/owner') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 2,
                  'asset_id': 12,
                  'asset_name': 'Camera',
                  'borrower_name': 'Alex',
                  'status': 'returned_pending',
                  'payment_status': 'paid',
                  'rental_days': 1,
                  'planned_return_date': '2030-01-01',
                },
              ],
            }),
            200,
          );
        }
        if (request.method == 'PATCH' &&
            request.url.path == '/api/borrows/2/confirm-return') {
          return http.Response(
            jsonEncode({'message': 'Return confirmed'}),
            200,
          );
        }
        return http.Response(jsonEncode({'message': 'Not found'}), 404);
      }),
    );
  });
}

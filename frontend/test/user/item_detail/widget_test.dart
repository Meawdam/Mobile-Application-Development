import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/item_detail/controller/item_detail_controller.dart';
import 'package:frontend/modules/user/item_detail/service/item_detail_api_service.dart';
import 'package:frontend/modules/user/item_detail/view/item_detail.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('shows item details loaded from the API', (tester) async {
    final service = ItemDetailApiService(
      baseUrl: 'https://example.test',
      authService: _TestAuthService(),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'id': 9,
              'owner_id': 2,
              'owner_username': 'Morgan',
              'name': 'Prime lens',
              'description': 'A sharp camera lens.',
              'status': 'ready',
              'approval': 'approved',
              'down_payment': 50,
              'return_before': '2030-01-10',
              'price': 12,
              'pickup_point': 'Library',
            },
          }),
          200,
        ),
      ),
    );

    final controller = ItemDetailController(apiService: service);
    await tester.pumpWidget(
      MaterialApp(
        home: ItemDetailScreen(assetId: 9, controller: controller),
        routes: {
          '/borrow-request': (_) =>
              const Scaffold(body: Text('Borrow request opened')),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prime lens'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('12 Baht'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Morgan'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Morgan'), findsOneWidget);

    await tester.tap(find.text('Request to borrow'));
    await tester.pumpAndSettle();
    expect(find.text('Borrow request opened'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    service.dispose();
  });

  testWidgets('shows a retry state when item details cannot be loaded', (
    tester,
  ) async {
    final service = ItemDetailApiService(
      authService: _TestAuthService(),
      client: MockClient(
        (_) async => http.Response(jsonEncode({'message': 'Unavailable'}), 503),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: ItemDetailScreen(assetId: 9, apiService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load this item'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async => 'test-token';
}

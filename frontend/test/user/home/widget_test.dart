import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/home/controller/home_controller.dart';
import 'package:frontend/modules/user/home/view/home.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('shows items loaded from the home API', (tester) async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'data': [
            {
              'id': 12,
              'owner_id': 3,
              'owner_username': 'Alex',
              'name': 'Camera',
              'description': 'Digital camera',
              'status': 'ready',
              'approval': 'approved',
              'down_payment': 0,
              'return_before': '2030-01-01',
              'price': 50,
              'pickup_point': 'Library',
            },
          ],
        }),
        200,
      ),
    );
    final controller = HomeController(
      client: client,
      baseUrl: 'https://example.test',
      authService: _TestAuthService(),
    );

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find what you need.'), findsOneWidget);
    expect(find.textContaining('Hello, Alex'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('฿50/day'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    client.close();
  });
}

class _TestAuthService extends Authservice {
  @override
  Future<String?> loadToken() async {
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'username': 'Alex', 'role': 'user'})))
        .replaceAll('=', '');
    return 'header.$payload.signature';
  }
}

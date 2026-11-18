// ไฟล์ม็อกกลางสำหรับ widget test (ใช้ mocktail เหมือน MockLoginController)
//
// วิธีใช้ในไฟล์ test:
//   import '../../helpers/mocks.dart';
//   void main() {
//     setUpAll(registerMockFallbacks);   // ต้องเรียกครั้งเดียวต่อไฟล์
//     ...
//     final client = MockHttpClient();
//     stubGet(client, '/api/assets/mine', jsonResponse({'data': []}));
//     final controller = MyLendingController(
//       client: client,
//       authService: mockAuthservice(),   // token = null จำลองว่ายังไม่ login
//     );
//   }

import 'dart:convert';

import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

/// http.Client จำลอง (แทน MockClient ของแพ็กเกจ http/testing)
class MockHttpClient extends Mock implements http.Client {}

/// Authservice จำลอง: ไม่แตะ secure storage จริง
class MockAuthservice extends Mock implements Authservice {}

/// ค่าสำรองที่ mocktail ต้องใช้เมื่อใช้ any() กับ Uri / BaseRequest
class FakeBaseRequest extends Fake implements http.BaseRequest {}

const String testBaseUrl = 'http://localhost:3000';
const String testToken = 'test-token';

/// เรียกใน setUpAll ของทุกไฟล์ที่ใช้ any() กับ Uri หรือ client.send(any())
void registerMockFallbacks() {
  registerFallbackValue(Uri());
  registerFallbackValue(FakeBaseRequest());
}

/// Authservice จำลองที่คืน [token] (ส่ง null = ยังไม่ได้ login)
MockAuthservice mockAuthservice({String? token = testToken}) {
  final auth = MockAuthservice();
  when(() => auth.loadToken()).thenAnswer((_) async => token);
  return auth;
}

/// URL เต็มของ endpoint ที่ controller เรียก เช่น apiUri('/api/assets/mine')
Uri apiUri(String path) => Uri.parse('$testBaseUrl$path');

/// header ที่ controller ต้องส่ง (ใช้กับ verify เพื่อเช็ก token)
/// [json] = false สำหรับ multipart (เช่น add item) ที่ไม่มี Content-Type
Map<String, String> expectedHeaders({bool json = true}) => {
  if (json) 'Content-Type': 'application/json',
  'Authorization': 'Bearer $testToken',
};

void stubGet(MockHttpClient client, String path, http.Response response) {
  when(
    () => client.get(apiUri(path), headers: any(named: 'headers')),
  ).thenAnswer((_) async => response);
}

void stubGetThrows(MockHttpClient client, Exception error) {
  when(
    () => client.get(any(), headers: any(named: 'headers')),
  ).thenAnswer((_) async => throw error);
}

void stubDelete(MockHttpClient client, String path, http.Response response) {
  when(
    () => client.delete(apiUri(path), headers: any(named: 'headers')),
  ).thenAnswer((_) async => response);
}

/// [withBody] = true เมื่อ controller ส่ง body ไปด้วย (เช่น edit item)
void stubPatch(
  MockHttpClient client,
  String path,
  http.Response response, {
  bool withBody = false,
}) {
  if (withBody) {
    when(
      () => client.patch(
        apiUri(path),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => response);
  } else {
    when(
      () => client.patch(apiUri(path), headers: any(named: 'headers')),
    ).thenAnswer((_) async => response);
  }
}

/// สำหรับ multipart (add item) ซึ่ง controller เรียก client.send(...)
void stubSend(MockHttpClient client, http.Response response) {
  when(() => client.send(any())).thenAnswer(
    (_) async => http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    ),
  );
}

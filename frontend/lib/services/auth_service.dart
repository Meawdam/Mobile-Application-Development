import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Authservice {
  final storage = FlutterSecureStorage();

  Future<void> saveToken(String jwt) async {
    await storage.write(key: 'token', value: jwt);
  }

  Future<String?> loadToken() async {
    String? token = await storage.read(key: 'token');
    return token;
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'token');
  }
}
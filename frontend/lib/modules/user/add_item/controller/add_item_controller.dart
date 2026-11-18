import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/date_utils.dart';

enum AddItemResult {
  success,
  missingFields,
  invalidPrice,
  invalidDeposit,
  missingImage,
  missingLendingEndDate,
  failed,
}

/// หน้า Add Item -> POST /api/assets (multipart/form-data, ต้องมี token)
class AddItemController extends ChangeNotifier {
  AddItemController({
    ImagePicker? picker,
    http.Client? client,
    Authservice? authService,
  }) : _picker = picker ?? ImagePicker(),
       _client = client ?? http.Client(),
       _authService = authService ?? Authservice();

  final ImagePicker _picker;
  final http.Client _client;
  final Authservice _authService;

  Uint8List? _imageBytes;
  String? _imageName;
  DateTime? _lendingEndDate;
  bool _submitting = false;
  String? _error;

  Uint8List? get imageBytes => _imageBytes;
  DateTime? get lendingEndDate => _lendingEndDate;
  bool get submitting => _submitting;
  String? get error => _error;

  Future<void> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setPickedImage(await file.readAsBytes(), file.name);
  }

  void setPickedImage(Uint8List bytes, String name) {
    _imageBytes = bytes;
    _imageName = name;
    notifyListeners();
  }

  void setLendingEndDate(DateTime date) {
    _lendingEndDate = AppDateUtils.dateOnly(date);
    notifyListeners();
  }

  /// backend ตรวจ mimetype + magic bytes ของรูป (jpeg/png/gif/webp)
  /// จึงดูจากไบต์ของไฟล์ก่อน ถ้าไม่ตรงค่อยดูจากนามสกุลไฟล์
  MediaType _mediaTypeFor(Uint8List bytes, String name) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return MediaType('image', 'jpeg');
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return MediaType('image', 'png');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return MediaType('image', 'gif');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return MediaType('image', 'webp');
    }
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  Future<AddItemResult> submit({
    required String name,
    required String description,
    required String price,
    required String deposit,
    required String pickupPoint,
  }) async {
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();
    final trimmedPickup = pickupPoint.trim();
    final trimmedPrice = price.trim();
    final trimmedDeposit = deposit.trim();

    if (trimmedName.isEmpty ||
        trimmedDescription.isEmpty ||
        trimmedPickup.isEmpty ||
        trimmedPrice.isEmpty ||
        trimmedDeposit.isEmpty) {
      return AddItemResult.missingFields;
    }

    final bytes = _imageBytes;
    final imageName = _imageName;
    if (bytes == null || imageName == null) {
      return AddItemResult.missingImage;
    }

    final endDate = _lendingEndDate;
    if (endDate == null) {
      return AddItemResult.missingLendingEndDate;
    }

    final parsedPrice = int.tryParse(trimmedPrice);
    if (parsedPrice == null || parsedPrice < 0 || parsedPrice > 2147483647) {
      return AddItemResult.invalidPrice;
    }

    final parsedDeposit = num.tryParse(trimmedDeposit);
    if (parsedDeposit == null ||
        !parsedDeposit.isFinite ||
        parsedDeposit < 0) {
      return AddItemResult.invalidDeposit;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    var result = AddItemResult.failed;
    try {
      // header: Authorization: Bearer <token> (multipart ไม่ต้องใส่ Content-Type)
      final token = await _authService.loadToken();
      final headers = <String, String>{
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };
      if (token == null || token.isEmpty) {
        _error = 'Please log in again';
      } else {
        // body: ฟิลด์ตามที่ Swagger POST /api/assets กำหนด
        final request =
            http.MultipartRequest('POST', Uri.parse('http://localhost:3000/api/assets'))
              ..headers.addAll(headers)
              ..fields.addAll({
                'name': trimmedName,
                'description': trimmedDescription,
                'down_payment': parsedDeposit.toString(),
                'price': parsedPrice.toString(),
                'pickup_point': trimmedPickup,
                'return_before': AppDateUtils.formatYmd(endDate),
              })
              ..files.add(
                http.MultipartFile.fromBytes(
                  'image',
                  bytes,
                  filename: imageName,
                  contentType: _mediaTypeFor(bytes, imageName),
                ),
              );

        final response = await http.Response.fromStream(
          await _client.send(request),
        );

        if (response.statusCode == 201) {
          result = AddItemResult.success;
        } else {
          _error = _messageFrom(response, 'Unable to submit item');
        }
      }
    } on Exception {
      _error = 'Connection error';
    }

    _submitting = false;
    notifyListeners();
    return result;
  }

  /// ดึงข้อความ error จาก body รูปแบบ { "message": "..." } ของ backend
  String _messageFrom(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // body ไม่ใช่ JSON ใช้ข้อความสำรอง
    }
    return fallback;
  }
}

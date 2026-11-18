import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/services/api_helper.dart';
import 'package:frontend/services/auth_service.dart';
import '../../shared/model/lending_item_model.dart';

/// ผลของการลบ: success=ลบได้, notFound=ไม่พบไอเทม,
/// forbidden=ไม่ใช่เจ้าของ, itemBorrowed=กำลังถูกยืมอยู่,
/// failed=เรียก backend ไม่สำเร็จ (ดูข้อความที่ error)
enum DeleteItemResult { success, notFound, forbidden, itemBorrowed, failed }

/// ควบคุมชีตยืนยันลบ: เปิดชีตสำหรับไอเทมหนึ่งชิ้น แล้วกดยืนยันลบหรือยกเลิก
/// เมื่อกดยืนยันจะเรียก DELETE /api/assets/:id (ต้องมี token และเป็นเจ้าของ)
class DeleteItemController extends ChangeNotifier {
  DeleteItemController({
    List<LendingItem> initialItems = const [],
    required this.currentUserId,
    http.Client? client,
    Authservice? authService,
  }) : _items = List.of(initialItems),
       _client = client ?? http.Client(),
       _authService = authService ?? Authservice();

  final List<LendingItem> _items;
  final String currentUserId;
  final http.Client _client;
  final Authservice _authService;
  LendingItem? _selected;
  String? _error;

  List<LendingItem> get items => List.unmodifiable(_items);
  LendingItem? get selectedItem => _selected;
  bool get isOpen => _selected != null;
  String? get error => _error;

  LendingItem? findById(String itemId) {
    final index = _items.indexWhere((i) => i.id == itemId);
    return index == -1 ? null : _items[index];
  }

  /// เปิดชีตสำหรับไอเทม คืน false ถ้าไม่พบไอเทม
  bool open(String itemId) {
    final item = findById(itemId);
    if (item == null) return false;
    _selected = item;
    _error = null;
    notifyListeners();
    return true;
  }

  /// ปิดชีตโดยไม่ลบ
  void cancel() {
    if (_selected == null) return;
    _selected = null;
    notifyListeners();
  }

  /// ตรวจกฎการลบ: ต้องพบไอเทม, เป็นเจ้าของ และไม่ได้กำลังถูกยืม
  DeleteItemResult check(String itemId) {
    final item = findById(itemId);
    if (item == null) return DeleteItemResult.notFound;
    if (item.ownerId != currentUserId) return DeleteItemResult.forbidden;
    if (item.isBorrowed) return DeleteItemResult.itemBorrowed;
    return DeleteItemResult.success;
  }

  /// ลบได้หรือไม่
  bool canDelete(String itemId) => check(itemId) == DeleteItemResult.success;

  /// กดยืนยันลบไอเทมที่เปิดชีตอยู่ ถ้า backend ลบสำเร็จจะลบออกจากลิสต์และปิดชีต
  Future<DeleteItemResult> confirmDelete() async {
    final item = _selected;
    if (item == null) return DeleteItemResult.notFound;

    final local = check(item.id);
    if (local != DeleteItemResult.success) {
      notifyListeners();
      return local;
    }

    _error = null;
    var result = DeleteItemResult.failed;
    try {
      final headers = await apiHeaders(_authService);
      if (!hasToken(headers)) {
        _error = 'Please log in again';
      } else {
        final response = await _client.delete(
          Uri.parse('$apiBaseUrl/api/assets/${item.id}'),
          headers: headers,
        );

        switch (response.statusCode) {
          case 200:
            result = DeleteItemResult.success;
          case 403:
            result = DeleteItemResult.forbidden;
          case 404:
            result = DeleteItemResult.notFound;
          case 409:
            result = DeleteItemResult.itemBorrowed;
          default:
            _error = apiMessage(response, 'Unable to delete item');
        }
      }
    } on Exception {
      _error = 'Connection error';
    }

    if (result == DeleteItemResult.success) {
      _items.removeWhere((i) => i.id == item.id);
      _selected = null;
    }
    notifyListeners();
    return result;
  }
}

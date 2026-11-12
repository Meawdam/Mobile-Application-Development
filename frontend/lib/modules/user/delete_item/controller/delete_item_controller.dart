import 'package:flutter/foundation.dart';

import '../../my_lending_items/controller/my_lending_controller.dart';
import '../../shared/model/lending_item_model.dart';

/// ผลของการลบ: success=ลบได้, notFound=ไม่พบไอเทม,
/// forbidden=ไม่ใช่เจ้าของ, itemBorrowed=กำลังถูกยืมอยู่
enum DeleteItemResult { success, notFound, forbidden, itemBorrowed }

/// ควบคุมชีตยืนยันลบ: เปิดชีตสำหรับไอเทมหนึ่งชิ้น แล้วกดยืนยันลบหรือยกเลิก
class DeleteItemController extends ChangeNotifier {
  DeleteItemController(this._lending, {required this.currentUserId});

  final MyLendingController _lending;
  final String currentUserId;
  LendingItem? _selected;

  LendingItem? get selectedItem => _selected;
  bool get isOpen => _selected != null;

  /// เปิดชีตสำหรับไอเทม คืน false ถ้าไม่พบไอเทม
  bool open(String itemId) {
    final item = _lending.findById(itemId);
    if (item == null) return false;
    _selected = item;
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
    final item = _lending.findById(itemId);
    if (item == null) return DeleteItemResult.notFound;
    if (item.ownerId != currentUserId) return DeleteItemResult.forbidden;
    if (item.isBorrowed) return DeleteItemResult.itemBorrowed;
    return DeleteItemResult.success;
  }

  /// ลบได้หรือไม่
  bool canDelete(String itemId) => check(itemId) == DeleteItemResult.success;

  /// กดยืนยันลบไอเทมที่เปิดชีตอยู่ ถ้าลบได้จะลบและปิดชีต
  DeleteItemResult confirmDelete() {
    final item = _selected;
    if (item == null) return DeleteItemResult.notFound;

    final result = check(item.id);
    if (result == DeleteItemResult.success) {
      _lending.removeItem(item.id);
      _selected = null;
    }
    notifyListeners();
    return result;
  }
}

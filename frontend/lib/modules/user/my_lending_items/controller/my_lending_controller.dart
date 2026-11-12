import 'package:flutter/foundation.dart';

import '../../shared/model/lending_item_model.dart';

/// ควบคุมหน้า My Lending: เก็บรายการไอเทมที่เราปล่อยยืม เพิ่ม/แก้/ลบ และนับจำนวน
/// ใช้ ChangeNotifier เพื่อให้หน้าจอรีเฟรชเมื่อข้อมูลเปลี่ยน
class MyLendingController extends ChangeNotifier {
  MyLendingController({List<LendingItem> initialItems = const []})
    : _items = List.of(initialItems);

  final List<LendingItem> _items;

  List<LendingItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get totalCount => _items.length;
  /// จำนวนไอเทมที่กำลังถูกยืม
  int get borrowedCount => _items.where((i) => i.isBorrowed).length;
  /// จำนวนไอเทมที่รอแอดมินอนุมัติ
  int get waitingApprovalCount =>
      _items.where((i) => i.approval == ApprovalStatus.pending).length;

  /// ค้นหาไอเทมจาก id (ไม่พบคืน null)
  LendingItem? findById(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    return index == -1 ? null : _items[index];
  }

  /// เพิ่มไอเทม คืน false ถ้ามี id ซ้ำ
  bool addItem(LendingItem item) {
    if (findById(item.id) != null) return false;
    _items.add(item);
    notifyListeners();
    return true;
  }

  /// แทนที่ไอเทมที่ id ตรงกัน คืน false ถ้าไม่พบ
  bool updateItem(LendingItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return false;
    _items[index] = item;
    notifyListeners();
    return true;
  }

  /// ลบไอเทม คืน false ถ้าไม่พบ
  bool removeItem(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return false;
    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  /// เปลี่ยนสถานะของไอเทม (เช่น กลับเป็น ready เมื่อได้ของคืน)
  bool setStatus(String id, ItemStatus status) {
    final item = findById(id);
    if (item == null) return false;
    return updateItem(item.copyWith(status: status));
  }
}

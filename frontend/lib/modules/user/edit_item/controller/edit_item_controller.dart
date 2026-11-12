import 'package:flutter/foundation.dart';

import '../../shared/model/lending_item_model.dart';
import '../../shared/item_validators.dart';

/// ผลของการบันทึก: success=สำเร็จ, validationFailed=ข้อมูลไม่ถูกต้อง,
/// itemBorrowed=ไอเทมกำลังถูกยืมจึงแก้ไม่ได้
enum EditItemResult { success, validationFailed, itemBorrowed }

/// ควบคุมหน้า Edit Item: แก้ได้เฉพาะราคา มัดจำ จุดรับ-คืน และวันที่คืน
/// (ชื่อและรายละเอียดแก้ไม่ได้ ตรงกับหน้าจอที่ล็อกช่องไว้)
class EditItemController extends ChangeNotifier {
  EditItemController(LendingItem item, {DateTime Function()? now})
    : _item = item,
      _now = now ?? DateTime.now;

  final DateTime Function() _now;
  LendingItem _item;
  Map<String, String> _errors = {};

  LendingItem get item => _item;
  Map<String, String> get errors => Map.unmodifiable(_errors);
  /// แก้ไขได้เมื่อไอเทมไม่ได้กำลังถูกยืม
  bool get canEdit => !_item.isBorrowed;

  /// ตรวจ 4 ช่องที่แก้ได้ (ราคา มัดจำ จุดรับ-คืน วันที่)
  Map<String, String> validate({
    required String price,
    required String deposit,
    required String pickupPoint,
    required DateTime? returnBefore,
  }) {
    final result = <String, String>{};
    void check(String key, String? msg) {
      if (msg != null) result[key] = msg;
    }

    check('price', ItemValidators.price(price));
    check('deposit', ItemValidators.deposit(deposit));
    check('pickupPoint', ItemValidators.pickupPoint(pickupPoint));
    check('returnBefore', ItemValidators.returnBefore(returnBefore, _now()));
    return result;
  }

  /// ค่าที่กรอกต่างจากไอเทมปัจจุบันหรือไม่ (ใช้เปิด/ปิดปุ่ม Save)
  bool hasChanges({
    required String price,
    required String deposit,
    required String pickupPoint,
    required DateTime? returnBefore,
  }) {
    if (price.trim() != _item.pricePerDay.toString()) return true;
    if (ItemValidators.parseDeposit(deposit) != _item.deposit) return true;
    if (pickupPoint.trim() != _item.pickupPoint) return true;
    if (returnBefore == null) return true;
    final d = DateTime(returnBefore.year, returnBefore.month, returnBefore.day);
    final cur = DateTime(
      _item.returnBefore.year,
      _item.returnBefore.month,
      _item.returnBefore.day,
    );
    return d != cur;
  }

  /// บันทึกการแก้ไข: ตรวจข้อมูลก่อน ถ้าผ่านจึงอัปเดตไอเทม
  EditItemResult save({
    required String price,
    required String deposit,
    required String pickupPoint,
    required DateTime? returnBefore,
  }) {
    if (!canEdit) return EditItemResult.itemBorrowed;

    _errors = validate(
      price: price,
      deposit: deposit,
      pickupPoint: pickupPoint,
      returnBefore: returnBefore,
    );
    if (_errors.isNotEmpty) {
      notifyListeners();
      return EditItemResult.validationFailed;
    }

    _item = _item.copyWith(
      pricePerDay: int.parse(price.trim()),
      deposit: ItemValidators.parseDeposit(deposit),
      pickupPoint: pickupPoint.trim(),
      returnBefore: DateTime(
        returnBefore!.year,
        returnBefore.month,
        returnBefore.day,
      ),
    );
    notifyListeners();
    return EditItemResult.success;
  }
}

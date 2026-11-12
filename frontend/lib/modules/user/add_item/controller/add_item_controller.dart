import 'package:flutter/foundation.dart';

import '../../shared/model/lending_item_model.dart';
import '../../shared/item_validators.dart';

/// ควบคุมหน้า Add Item: ตรวจฟอร์มและสร้างไอเทมใหม่
/// ไอเทมที่สร้างจะมีสถานะ 'รอแอดมินอนุมัติ'
class AddItemController extends ChangeNotifier {
  AddItemController({required this.ownerId, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// id ของเจ้าของไอเทม (ผู้ใช้ที่ล็อกอินอยู่)
  final String ownerId;
  /// ฟังก์ชันบอกเวลาปัจจุบัน แยกไว้เพื่อให้เทสกำหนดวันที่เองได้
  final DateTime Function() _now;

  final List<LendingItem> _submitted = [];
  Map<String, String> _errors = {};
  String? _imagePath;
  int _nextId = 1;

  List<LendingItem> get submittedItems => List.unmodifiable(_submitted);
  Map<String, String> get errors => Map.unmodifiable(_errors);
  String? get imagePath => _imagePath;
  bool get hasErrors => _errors.isNotEmpty;

  /// เลือกรูปไอเทม (path ว่าง = ล้างรูป)
  void setImage(String? path) {
    _imagePath = (path == null || path.trim().isEmpty) ? null : path;
    notifyListeners();
  }

  /// ตรวจทุกช่อง คืน Map ชื่อช่อง -> ข้อความ error
  /// ถ้า Map ว่างแปลว่าฟอร์มถูกต้อง
  Map<String, String> validate({
    required String name,
    required String price,
    required String deposit,
    required String pickupPoint,
    required DateTime? returnBefore,
  }) {
    final result = <String, String>{};
    void check(String key, String? msg) {
      if (msg != null) result[key] = msg;
    }

    check('name', ItemValidators.name(name));
    check('price', ItemValidators.price(price));
    check('deposit', ItemValidators.deposit(deposit));
    check('pickupPoint', ItemValidators.pickupPoint(pickupPoint));
    check('returnBefore', ItemValidators.returnBefore(returnBefore, _now()));
    return result;
  }

  /// ตรวจฟอร์มแล้วสร้างไอเทมสถานะรออนุมัติ
  /// คืนไอเทมที่สร้าง หรือ null ถ้าตรวจไม่ผ่าน (ดูข้อผิดพลาดที่ errors)
  LendingItem? submit({
    required String name,
    String description = '',
    required String price,
    String deposit = '',
    required String pickupPoint,
    required DateTime? returnBefore,
  }) {
    _errors = validate(
      name: name,
      price: price,
      deposit: deposit,
      pickupPoint: pickupPoint,
      returnBefore: returnBefore,
    );
    if (_errors.isNotEmpty) {
      notifyListeners();
      return null;
    }

    final item = LendingItem(
      id: 'new${_nextId++}',
      ownerId: ownerId,
      name: name.trim(),
      description: description.trim(),
      imagePath: _imagePath,
      pricePerDay: int.parse(price.trim()),
      deposit: ItemValidators.parseDeposit(deposit),
      pickupPoint: pickupPoint.trim(),
      returnBefore: DateTime(
        returnBefore!.year,
        returnBefore.month,
        returnBefore.day,
      ),
      status: ItemStatus.ready,
      approval: ApprovalStatus.pending,
    );
    _submitted.add(item);
    _imagePath = null;
    notifyListeners();
    return item;
  }
}

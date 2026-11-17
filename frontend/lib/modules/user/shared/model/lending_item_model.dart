/// สถานะของไอเทม: ready=พร้อมให้ยืม, pending=รอดำเนินการ, borrowed=กำลังถูกยืม, unavailable=ไม่พร้อมให้ยืม
enum ItemStatus { ready, pending, borrowed, unavailable }

/// สถานะการอนุมัติจากแอดมิน: pending=รออนุมัติ, approved=อนุมัติแล้ว, notApproved=ไม่อนุมัติ
enum ApprovalStatus { pending, approved, notApproved }

/// แปลงข้อความจาก backend เป็น ItemStatus (ถ้าไม่รู้จักจะใช้ ready)
ItemStatus _statusFrom(String? v) => ItemStatus.values.firstWhere(
  (e) => e.name == v,
  orElse: () => ItemStatus.ready,
);

/// แปลงข้อความจาก backend เป็น ApprovalStatus (backend ใช้คำว่า 'not approve' มีช่องว่าง)
ApprovalStatus _approvalFrom(String? v) {
  switch (v) {
    case 'approved':
      return ApprovalStatus.approved;
    case 'not approve':
      return ApprovalStatus.notApproved;
    default:
      return ApprovalStatus.pending;
  }
}

/// แปลง ApprovalStatus กลับเป็นข้อความที่ backend ใช้
String _approvalTo(ApprovalStatus a) {
  switch (a) {
    case ApprovalStatus.approved:
      return 'approved';
    case ApprovalStatus.notApproved:
      return 'not approve';
    case ApprovalStatus.pending:
      return 'pending';
  }
}

/// ข้อมูลไอเทมที่เจ้าของปล่อยให้ยืม (ตรงกับตาราง asset ใน backend)
/// ใช้ร่วมกันหลายหน้า จึงเก็บไว้ในโฟลเดอร์ shared/model
class LendingItem {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String? imagePath;
  /// ราคาต่อวัน (บาท)
  final int pricePerDay;
  /// เงินมัดจำ (บาท)
  final double deposit;
  final String pickupPoint;
  /// วันสุดท้ายที่ต้องคืน
  final DateTime returnBefore;
  final ItemStatus status;
  final ApprovalStatus approval;

  const LendingItem({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description = '',
    this.imagePath,
    required this.pricePerDay,
    this.deposit = 0,
    required this.pickupPoint,
    required this.returnBefore,
    this.status = ItemStatus.ready,
    this.approval = ApprovalStatus.pending,
  });

  /// ไอเทมนี้กำลังถูกยืมอยู่หรือไม่
  bool get isBorrowed => status == ItemStatus.borrowed;

  /// สร้างสำเนาใหม่โดยเปลี่ยนเฉพาะฟิลด์ที่ระบุ (id และ ownerId ไม่เปลี่ยน)
  LendingItem copyWith({
    String? name,
    String? description,
    String? imagePath,
    int? pricePerDay,
    double? deposit,
    String? pickupPoint,
    DateTime? returnBefore,
    ItemStatus? status,
    ApprovalStatus? approval,
  }) {
    return LendingItem(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      deposit: deposit ?? this.deposit,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      returnBefore: returnBefore ?? this.returnBefore,
      status: status ?? this.status,
      approval: approval ?? this.approval,
    );
  }

  /// แปลง Map จาก backend (เช่น down_payment, pickup_point) เป็น LendingItem
  /// ถ้าข้อมูลหายหรือผิดรูปแบบ จะใช้ค่าเริ่มต้นแทน
  factory LendingItem.fromMap(Map<String, dynamic> map) {
    return LendingItem(
      id: map['id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imagePath: map['image']?.toString(),
      pricePerDay: int.tryParse(map['price']?.toString() ?? '') ?? 0,
      deposit: double.tryParse(map['down_payment']?.toString() ?? '') ?? 0,
      pickupPoint: map['pickup_point']?.toString() ?? '',
      returnBefore:
          DateTime.tryParse(map['return_before']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _statusFrom(map['status']?.toString()),
      approval: _approvalFrom(map['approval']?.toString()),
    );
  }

  /// แปลง LendingItem กลับเป็น Map (วันที่เป็นรูปแบบ yyyy-MM-dd)
  Map<String, dynamic> toMap() {
    final d = returnBefore;
    final date =
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'image': imagePath,
      'price': pricePerDay,
      'down_payment': deposit,
      'pickup_point': pickupPoint,
      'return_before': date,
      'status': status.name,
      'approval': _approvalTo(approval),
    };
  }
}

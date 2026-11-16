/// ตรวจข้อมูลฟอร์มที่ใช้ร่วมกันระหว่างหน้า Add Item และ Edit Item
/// แต่ละเมธอดคืนข้อความ error ถ้าไม่ผ่าน หรือคืน null ถ้าข้อมูลถูกต้อง
class ItemValidators {
  static const int maxInt = 2147483647;

  /// ชื่อ: ห้ามว่าง และไม่เกิน 100 ตัวอักษร
  static String? name(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Item name is required';
    if (s.length > 100) return 'Item name must not exceed 100 characters';
    return null;
  }

  /// ราคา: ต้องเป็นจำนวนเต็มที่ไม่ติดลบ และไม่เกินช่วงของฐานข้อมูล
  static String? price(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Price is required';
    if (!RegExp(r'^\d+$').hasMatch(s)) {
      return 'Price must be a non-negative whole number';
    }
    final n = int.tryParse(s);
    if (n == null || n > maxInt) return 'Price is too large';
    return null;
  }

  /// มัดจำ: เว้นว่างได้ (ถือเป็น 0) แต่ถ้าใส่ต้องเป็นตัวเลขที่ไม่ติดลบ
  static String? deposit(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final n = double.tryParse(s);
    if (n == null || n.isNaN || n.isInfinite || n < 0) {
      return 'Deposit must be a non-negative number';
    }
    return null;
  }

  /// จุดรับ-คืน: ห้ามว่าง และไม่เกิน 255 ตัวอักษร
  static String? pickupPoint(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Pickup location is required';
    if (s.length > 255) return 'Pickup location must not exceed 255 characters';
    return null;
  }

  /// วันที่: ต้องเป็นวันนี้หรืออนาคต (ไม่นับเวลา)
  static String? returnBefore(DateTime? v, DateTime now) {
    if (v == null) return 'Date is required';
    final d = DateTime(v.year, v.month, v.day);
    final today = DateTime(now.year, now.month, now.day);
    if (d.isBefore(today)) return 'Date must be today or later';
    return null;
  }

  /// แปลงข้อความมัดจำเป็นตัวเลข (ว่างหรืออ่านไม่ได้ = 0)
  static double parseDeposit(String? v) =>
      double.tryParse((v ?? '').trim()) ?? 0;
}

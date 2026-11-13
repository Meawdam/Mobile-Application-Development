/// สถานะการยืม ตรงกับ backend:
/// requested=ขอยืม, approved=อนุมัติ, borrowed=รับของไปแล้ว,
/// returnedPending=ผู้ยืมแจ้งคืนแล้ว รอเจ้าของยืนยัน,
/// returnedConfirmed=เจ้าของยืนยันว่าได้ของคืนแล้ว, rejected=ปฏิเสธ
enum BorrowStatus {
  requested,
  approved,
  borrowed,
  returnedPending,
  returnedConfirmed,
  rejected,
}

/// รายการยืม-คืนที่มองจากฝั่งเจ้าของของ (ตรงกับตาราง borrow ใน backend)
class ReturnRequest {
  final String id;
  final String assetId;
  final String assetName;
  final String ownerId;
  final String borrowerName;
  final BorrowStatus status;
  final int fineAmount;

  const ReturnRequest({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.ownerId,
    required this.borrowerName,
    required this.status,
    this.fineAmount = 0,
  });

  /// ผู้ยืมแจ้งคืนแล้ว และกำลังรอเจ้าของยืนยันหรือไม่
  bool get isAwaitingConfirmation => status == BorrowStatus.returnedPending;

  /// สร้างสำเนาใหม่โดยเปลี่ยนเฉพาะสถานะหรือค่าปรับ
  ReturnRequest copyWith({BorrowStatus? status, int? fineAmount}) {
    return ReturnRequest(
      id: id,
      assetId: assetId,
      assetName: assetName,
      ownerId: ownerId,
      borrowerName: borrowerName,
      status: status ?? this.status,
      fineAmount: fineAmount ?? this.fineAmount,
    );
  }

  /// แปลง Map จาก backend เป็น ReturnRequest
  factory ReturnRequest.fromMap(Map<String, dynamic> map) {
    BorrowStatus parse(String? v) {
      switch (v) {
        case 'approved':
          return BorrowStatus.approved;
        case 'borrowed':
          return BorrowStatus.borrowed;
        case 'returned_pending':
          return BorrowStatus.returnedPending;
        case 'returned_confirmed':
          return BorrowStatus.returnedConfirmed;
        case 'rejected':
          return BorrowStatus.rejected;
        default:
          return BorrowStatus.requested;
      }
    }

    return ReturnRequest(
      id: map['id']?.toString() ?? '',
      assetId: map['asset_id']?.toString() ?? '',
      assetName: map['asset_name']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      borrowerName: map['borrower_name']?.toString() ?? '',
      status: parse(map['status']?.toString()),
      fineAmount: int.tryParse(map['fine_amount']?.toString() ?? '') ?? 0,
    );
  }
}

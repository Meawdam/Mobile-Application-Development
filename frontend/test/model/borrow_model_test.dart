import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/model/borrow/borrow_model.dart';

void main() {
  test('fromJson maps borrow day and payment amount fields', () {
    final borrow = BorrowModel.fromJson({
      'id': 11,
      'asset_id': 4,
      'asset_name': 'Lens',
      'owner_name': 'Ann',
      'borrower_name': 'Bob',
      'pickup_point': 'Gate',
      'pickup_date': '2026-11-12',
      'planned_return_date': '2026-11-14',
      'rental_days': 3,
      'lending_end_date': '2026-12-01',
      'price_per_day': 100,
      'rental_amount': 300,
      'deposit_amount': 500,
      'total_amount': 800,
      'fine_amount': 0,
      'status': 'borrowed',
      'payment_status': 'paid',
    });

    expect(borrow.id, 11);
    expect(borrow.assetId, 4);
    expect(borrow.rentalDays, 3);
    expect(borrow.pickupDate, '2026-11-12');
    expect(borrow.plannedReturnDate, '2026-11-14');
    expect(borrow.rentalSubtotal, 300);
    expect(borrow.deposit, 500);
    expect(borrow.totalAmount, 800);
    expect(borrow.status, 'borrowed');
    expect(borrow.paymentStatus, 'paid');
  });

  test('fromJson accepts alternate amount field names', () {
    final borrow = BorrowModel.fromJson({
      'id': 1,
      'asset_id': 2,
      'rental_days': 2,
      'rental_subtotal': 200,
      'down_payment': '150',
      'return_before': '2026-11-30T00:00:00.000Z',
      'status': 'requested',
      'payment_status': 'unpaid',
    });

    expect(borrow.rentalSubtotal, 200);
    expect(borrow.deposit, 150);
    expect(borrow.lendingEndDate, '2026-11-30');
  });
}

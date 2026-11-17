import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';

class MyBorrowedController extends ChangeNotifier {
  MyBorrowedController({List<BorrowModel>? initialItems})
      : items = List.of(initialItems ?? const []);

  List<BorrowModel> items;
  bool loading = false;
  String? error;

  num get heldDeposit => items
      .where(
        (b) =>
            b.paymentStatus == 'paid' &&
            (b.status == 'borrowed' || b.status == 'returned_pending'),
      )
      .fold<num>(0, (sum, b) => sum + (b.deposit ?? 0));

  List<BorrowModel> get borrowing => items
      .where((b) => b.status == 'borrowed' || b.status == 'returned_pending')
      .toList();

  List<BorrowModel> get pending => items
      .where(
        (b) =>
            b.status == 'requested' ||
            (b.status == 'approved' && b.paymentStatus == 'unpaid'),
      )
      .toList();

  List<BorrowModel> get returned =>
      items.where((b) => b.status == 'returned_confirmed').toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    loading = false;
    notifyListeners();
  }

  Future<String?> cancel(int borrowId) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    final borrow = items[index];
    final canCancel = borrow.status == 'requested' ||
        (borrow.status == 'approved' && borrow.paymentStatus == 'unpaid');
    if (!canCancel) {
      return 'Only pending requests can be cancelled';
    }
    items.removeAt(index);
    await load();
    return null;
  }

  Future<String?> requestReturn(int borrowId) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    final borrow = items[index];
    if (borrow.status != 'borrowed') return 'Borrow is not active';
    items[index] = borrow.copyWith(status: 'returned_pending');
    await load();
    return null;
  }
}

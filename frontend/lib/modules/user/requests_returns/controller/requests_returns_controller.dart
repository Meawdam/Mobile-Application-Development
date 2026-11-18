import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';

class RequestsReturnsController extends ChangeNotifier {
  RequestsReturnsController({List<BorrowModel>? initialItems})
      : items = List.of(initialItems ?? const []);

  List<BorrowModel> items;
  bool loading = false;
  String? error;

  /// Unpaid/new requests waiting on borrower payment, plus returns awaiting owner confirm.
  List<BorrowModel> get waitingForResponse => items
      .where(
        (b) =>
            (b.status == 'requested' && b.paymentStatus == 'unpaid') ||
            b.status == 'returned_pending',
      )
      .toList();

  List<BorrowModel> get borrowedItems =>
      items.where((b) => b.status == 'borrowed').toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    loading = false;
    notifyListeners();
  }

  Future<String?> confirmReturn(int borrowId) async {
    final index = items.indexWhere((item) => item.id == borrowId);
    if (index == -1) return 'Borrow not found';
    final borrow = items[index];
    if (borrow.status != 'returned_pending') {
      return 'Return has not been requested';
    }
    items[index] = borrow.copyWith(status: 'returned_confirmed');
    await load();
    return null;
  }
}

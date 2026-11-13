import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';

class BorrowDetailsController extends ChangeNotifier {
  BorrowDetailsController({List<BorrowModel>? borrows})
      : _borrows = borrows ?? <BorrowModel>[];

  final List<BorrowModel> _borrows;
  BorrowModel? borrow;
  bool loading = false;
  String? error;

  Future<void> load(int borrowId) async {
    loading = true;
    error = null;
    notifyListeners();
    borrow = null;
    for (final item in _borrows) {
      if (item.id == borrowId) {
        borrow = item;
        break;
      }
    }
    if (borrow == null) error = 'Borrow not found';
    loading = false;
    notifyListeners();
  }

  Future<String?> requestReturn() async {
    final currentBorrow = borrow;
    if (currentBorrow == null) return 'Missing borrow';
    if (currentBorrow.status != 'borrowed') return 'Borrow is not active';

    borrow = currentBorrow.copyWith(status: 'returned_pending');
    _updateBorrow(borrow!);
    notifyListeners();
    return null;
  }

  Future<String?> confirmReturn() async {
    final currentBorrow = borrow;
    if (currentBorrow == null) return 'Missing borrow';
    if (currentBorrow.status != 'returned_pending') {
      return 'Return has not been requested';
    }

    borrow = currentBorrow.copyWith(status: 'returned_confirmed');
    _updateBorrow(borrow!);
    notifyListeners();
    return null;
  }

  void _updateBorrow(BorrowModel updated) {
    final index = _borrows.indexWhere((item) => item.id == updated.id);
    if (index != -1) _borrows[index] = updated;
  }
}

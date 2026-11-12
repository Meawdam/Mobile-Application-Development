import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/borrow_api.dart';

class MyBorrowedController extends ChangeNotifier {
  MyBorrowedController({BorrowApi? borrowApi})
      : _borrowApi = borrowApi ?? BorrowApi();

  final BorrowApi _borrowApi;

  List<BorrowModel> items = const [];
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
    try {
      items = await _borrowApi.getMyBorrows();
    } on ApiException catch (e) {
      error = e.message;
      items = const [];
    } catch (_) {
      error = 'Unable to load borrowed items';
      items = const [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> cancel(int borrowId) async {
    try {
      await _borrowApi.cancel(borrowId);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to cancel request';
    }
  }

  Future<String?> requestReturn(int borrowId) async {
    try {
      await _borrowApi.requestReturn(borrowId);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to request return';
    }
  }
}

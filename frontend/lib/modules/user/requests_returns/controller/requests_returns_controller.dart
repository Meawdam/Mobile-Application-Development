import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/borrow_api.dart';

class RequestsReturnsController extends ChangeNotifier {
  RequestsReturnsController({BorrowApi? borrowApi})
      : _borrowApi = borrowApi ?? BorrowApi();

  final BorrowApi _borrowApi;

  List<BorrowModel> items = const [];
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
    try {
      items = await _borrowApi.getMyLendingBorrows();
    } on ApiException catch (e) {
      error = e.message;
      items = const [];
    } catch (_) {
      error = 'Unable to load requests and returns';
      items = const [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> confirmReturn(int borrowId) async {
    try {
      await _borrowApi.confirmReturn(borrowId);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to confirm return';
    }
  }
}

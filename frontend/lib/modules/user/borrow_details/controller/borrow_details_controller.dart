import 'package:flutter/foundation.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/borrow_api.dart';

class BorrowDetailsController extends ChangeNotifier {
  BorrowDetailsController({BorrowApi? borrowApi})
      : _borrowApi = borrowApi ?? BorrowApi();

  final BorrowApi _borrowApi;

  BorrowModel? borrow;
  bool loading = false;
  String? error;

  Future<void> load(int borrowId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      borrow = await _borrowApi.getBorrowById(borrowId);
    } on ApiException catch (e) {
      borrow = null;
      error = e.message;
    } catch (_) {
      borrow = null;
      error = 'Unable to load borrow details';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> requestReturn() async {
    final id = borrow?.id;
    if (id == null) return 'Missing borrow';
    try {
      await _borrowApi.requestReturn(id);
      await load(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to request return';
    }
  }

  Future<String?> confirmReturn() async {
    final id = borrow?.id;
    if (id == null) return 'Missing borrow';
    try {
      await _borrowApi.confirmReturn(id);
      await load(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to confirm return';
    }
  }
}

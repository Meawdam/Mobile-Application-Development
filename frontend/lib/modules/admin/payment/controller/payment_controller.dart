import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../services/auth_service.dart';
import '../model/payment_model.dart';
import '../../admin_time.dart';

class PaymentController {
  static const String _baseUrl = 'http://localhost:3000';

  final Authservice _authService = Authservice();

  bool isLoading = false;
  String? errorMessage;

  // โหลดรายการธุรกรรมจาก Backend
  Future<List<PaymentTransaction>> fetchTransactions({
    String? type,
    String? status,
    String? search,
    int limit = 100,
    int offset = 0,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final token = await _getToken();

      final queryParameters = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (type != null && type.isNotEmpty) {
        queryParameters['type'] = type;
      }

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final uri = Uri.parse('$_baseUrl/api/admin/transactions')
          .replace(queryParameters: queryParameters);

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('No access to data; please check the Admin Token.');
      }

      if (response.statusCode != 200) {
        throw Exception(_getErrorMessage(response));
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Transaction data format is incorrect.');
      }

      final rawData = decoded['data'];

      if (rawData is! List) {
        throw Exception('No transaction records found from the backend.');
      }

      final transactions = <PaymentTransaction>[];

      for (final item in rawData) {
        if (item is! Map) continue;

        final data = Map<String, dynamic>.from(item);
        final transaction = _createTransaction(data);

        transactions.add(transaction);
      }

      return transactions;
    } catch (e) {
      errorMessage = _cleanError(e);
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  // คืนเงินมัดจำที่รอดำเนินการ
  Future<bool> refundTransaction(PaymentTransaction transaction) async {
    final transactionId = transaction.id;

    if (transactionId.isEmpty) {
      errorMessage = 'Transaction ID not found. Please reload the list.';
      return false;
    }

    return refundById(transactionId);
  }

  // คืนเงินโดยใช้รหัสธุรกรรมโดยตรง
  Future<bool> refundById(String transactionId) async {
    try {
      final token = await _getToken();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/admin/transactions/$transactionId/refund'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Not eligible for a refund');
      }

      if (response.statusCode != 200) {
        throw Exception(_getErrorMessage(response));
      }

      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    }
  }

  // กรองรายการธุรกรรมตาม Tab เดิม
  List<PaymentTransaction> filterTransactions(
    List<PaymentTransaction> transactions,
    String filter,
  ) {
    return transactions.where((tx) {
      if (filter == 'Pending Refund') {
        return tx.isRefundable;
      } else if (filter == 'Collected') {
        return tx.isIncome && !tx.isPending;
      } else if (filter == 'Refunded') {
        return !tx.isIncome;
      }

      return true;
    }).toList();
  }

  // ตรวจสอบความถูกต้องของยอดเงิน
  bool validateAmount(double amount) {
    return amount > 0;
  }

  // แปลงข้อมูล API เป็น Payment Model เดิม
  PaymentTransaction _createTransaction(Map<String, dynamic> data) {
    final type = _value(data, ['transaction_type', 'type']).toLowerCase();
    final status = _value(data, ['status']).toLowerCase();

    final isIncome = !['deposit_refund', 'borrow_refund'].contains(type);

    final isPending = status == 'pending';
    final isRefundable = type == 'deposit_refund' && isPending;

    final title = _value(data, [
      'title',
      'description',
      'transaction_type',
      'type',
    ], fallback: 'Transaction');

    final user = _value(data, [
      'user',
      'username',
      'borrower_name',
      'user_name',
    ], fallback: '-');

    final time = formatAdminTime(_value(data, ['time', 'created_at', 'transaction_date']));

    final amountValue =
        data['amount'] ?? data['total_amount'] ?? data['value'] ?? 0;

    return PaymentTransaction.fromJson({
      'id': data['id'] ?? data['transaction_id'],
      'title': title,
      'user': user,
      'time': time,
      'amount': _formatAmount(amountValue, isIncome),
      'isIncome': isIncome,
      'isPending': isPending,
      'isRefundable': isRefundable,
    });
  }

  String _formatAmount(dynamic value, bool isIncome) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    final parts = amount.abs().toStringAsFixed(2).split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${isIncome ? '+' : '-'}฿$whole.${parts.last}';
  }

  Future<String> _getToken() async {
    final token = await _authService.loadToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token not found. Please log in again.');
    }

    return token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _value(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String _getErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            'An error occurred. (${response.statusCode})';
      }
    } catch (_) {
      // ใช้ข้อความสำรองเมื่อ Response ไม่ใช่ JSON
    }

    return 'An error occurred. (${response.statusCode})';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

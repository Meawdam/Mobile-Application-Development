import 'package:flutter/material.dart';

import 'package:frontend/modules/user/payment/controller/payment_controller.dart';
import 'package:frontend/utils/date_utils.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? args;

  const PaymentScreen({super.key, this.args});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _controller = PaymentController();

  int? get _borrowId => _asInt(widget.args?['borrowId']);
  int get _days => _asInt(widget.args?['days']) ?? 0;
  num get _deposit => _asNum(widget.args?['deposit']) ?? 0;
  num get _rental => _asNum(widget.args?['rentalSubtotal']) ?? 0;
  num get _total => _asNum(widget.args?['total']) ?? (_rental + _deposit);
  String get _pickup => widget.args?['pickupDate']?.toString() ?? '—';
  String get _return => widget.args?['returnDate']?.toString() ?? '—';
  String get _lendingEnd =>
      widget.args?['lendingEndDate']?.toString() ?? '—';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.loadWallet();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    final borrowId = _borrowId;
    if (borrowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing borrow request')),
      );
      return;
    }

    final result = await _controller.confirmPayment(
      borrowId: borrowId,
      total: _total,
    );
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.error ?? 'Unable to complete payment'),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/borrow-details',
      (route) => route.settings.name == '/home' || route.isFirst,
      arguments: {'borrowId': borrowId},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment completed')),
    );
  }

  String _displayDate(String raw) {
    final parsed = AppDateUtils.tryParseYmd(raw);
    return parsed == null ? raw : AppDateUtils.formatDisplay(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = _controller.canPay(_total);
    final busy = _controller.paying || _controller.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2F4BFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total amount due',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_total Baht',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Text(
                    'Rental fee: $_rental · Deposit: $_deposit',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_days day(s)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup: ${_displayDate(_pickup)}'),
                  const SizedBox(height: 6),
                  Text('Return: ${_displayDate(_return)}'),
                  const SizedBox(height: 6),
                  Text('Lending end date: ${_displayDate(_lendingEnd)}'),
                  const SizedBox(height: 12),
                  Text(
                    _controller.loading
                        ? 'Wallet balance: ...'
                        : 'Wallet balance: ${_controller.walletBalance} Baht',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: canAfford ? Colors.black87 : Colors.red,
                    ),
                  ),
                  if (!canAfford && !_controller.loading) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Insufficient balance. Top up your wallet first.',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/wallet');
                        await _controller.loadWallet();
                      },
                      child: const Text('Go to Wallet'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The deposit will be held until the item is returned.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy || _borrowId == null || !canAfford
                    ? null
                    : _confirmPayment,
                child: Text(
                  _controller.paying ? 'Processing...' : 'Confirm payment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static num? _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}

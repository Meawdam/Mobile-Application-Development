import 'package:flutter/material.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/payment/controller/payment_controller.dart';
import 'package:frontend/utils/date_utils.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  final PaymentController? controller;

  const PaymentScreen({super.key, this.args, this.controller});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentController _controller =
      widget.controller ?? PaymentController();

  int? get _borrowId => _asInt(widget.args?['borrowId']);
  BorrowModel? get _borrow => _controller.borrow;
  int get _days => _borrow?.rentalDays ?? _asInt(widget.args?['days']) ?? 0;
  num get _deposit => _borrow?.deposit ?? _asNum(widget.args?['deposit']) ?? 0;
  num get _rental =>
      _borrow?.rentalSubtotal ?? _asNum(widget.args?['rentalSubtotal']) ?? 0;
  num get _total =>
      _borrow?.totalAmount ??
      _asNum(widget.args?['total']) ??
      (_rental + _deposit);
  String get _pickup =>
      _borrow?.pickupDate ?? widget.args?['pickupDate']?.toString() ?? '—';
  String get _return =>
      _borrow?.plannedReturnDate ??
      widget.args?['returnDate']?.toString() ??
      '—';
  String get _lendingEnd =>
      _borrow?.lendingEndDate ??
      widget.args?['lendingEndDate']?.toString() ??
      '—';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.loadPayment(_borrowId);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    final borrowId = _borrowId;
    if (borrowId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing borrow request')));
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

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/borrow-details',
      (route) => route.settings.name == '/home' || route.isFirst,
      arguments: {'borrowId': borrowId},
    );
    messenger.showSnackBar(const SnackBar(content: Text('Payment completed')));
  }

  String _displayDate(String raw) {
    final parsed = AppDateUtils.tryParseYmd(raw);
    return parsed == null ? raw : AppDateUtils.formatDisplay(parsed);
  }

  String _money(num amount) => amount.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final canAfford = _controller.canPay(_total);
    final alreadyPaid = _borrow?.paymentStatus == 'paid';
    final busy = _controller.paying || _controller.loading;
    final canConfirm =
        !busy &&
        _borrowId != null &&
        _borrow != null &&
        canAfford &&
        !alreadyPaid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFFF6F7FB),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3156D8), Color(0xFF6047C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x223156D8),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 17,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'SECURE CHECKOUT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    if (alreadyPaid)
                      const _PaymentStatus(label: 'Paid', paid: true),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Total amount due',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  '฿${_money(_total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 14),
                _SummaryRow(label: 'Rental fee', amount: _rental),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Refundable deposit', amount: _deposit),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.event_note_outlined,
            title: 'Borrowing schedule',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: Column(
              children: [
                _ScheduleRow(
                  label: 'Pickup',
                  value: _displayDate(_pickup),
                  icon: Icons.login_rounded,
                ),
                const Divider(height: 22),
                _ScheduleRow(
                  label: 'Return',
                  value: _displayDate(_return),
                  icon: Icons.logout_rounded,
                ),
                const Divider(height: 22),
                _ScheduleRow(
                  label: 'Lending available until',
                  value: _displayDate(_lendingEnd),
                  icon: Icons.calendar_month_outlined,
                ),
                const Divider(height: 22),
                _ScheduleRow(
                  label: 'Rental duration',
                  value: '$_days day${_days == 1 ? '' : 's'}',
                  icon: Icons.timelapse_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payment method',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDFF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF3156D8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet balance',
                        style: TextStyle(
                          color: Color(0xFF17233C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_controller.loading)
                        const Text(
                          'Checking your balance...',
                          style: TextStyle(color: Color(0xFF667085)),
                        )
                      else if (_controller.loadError != null)
                        Text(
                          _controller.loadError!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          '฿${_money(_controller.walletBalance)} available',
                          style: TextStyle(
                            color: canAfford
                                ? const Color(0xFF20845A)
                                : const Color(0xFFB42318),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_controller.loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_controller.loadError != null)
                  IconButton(
                    tooltip: 'Retry loading payment details',
                    onPressed: () => _controller.loadPayment(_borrowId),
                    icon: const Icon(Icons.refresh),
                  )
                else
                  Icon(
                    canAfford ? Icons.check_circle : Icons.error_outline,
                    color: canAfford
                        ? const Color(0xFF20845A)
                        : const Color(0xFFB42318),
                  ),
              ],
            ),
          ),
          if (!canAfford &&
              !_controller.loading &&
              _controller.loadError == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your wallet balance is not enough for this payment.',
                      style: TextStyle(color: Color(0xFFB42318), fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/wallet');
                      if (mounted) _controller.loadPayment(_borrowId);
                    },
                    child: const Text('Add funds'),
                  ),
                ],
              ),
            ),
          if (_controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _controller.error!,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF3156D8), size: 19),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The deposit is held during the borrowing period and returned after the item is confirmed as returned.',
                    style: TextStyle(
                      color: Color(0xFF42526B),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: FilledButton(
          onPressed: canConfirm ? _confirmPayment : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: const Color(0xFF3156D8),
            disabledBackgroundColor: const Color(0xFFCBD1DC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: busy
              ? const SizedBox(
                  height: 21,
                  width: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  alreadyPaid ? 'Payment already completed' : 'Pay from wallet',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  static const _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(17)),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFFE8EBF2))),
  );

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF3156D8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF17233C),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.amount});

  final String label;
  final num amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Text(
          '฿${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF667085)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF17233C),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaymentStatus extends StatelessWidget {
  const _PaymentStatus({required this.label, required this.paid});

  final String label;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: paid ? const Color(0xFF20845A) : Colors.white24,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

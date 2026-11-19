import 'package:flutter/material.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/borrow_details/controller/borrow_details_controller.dart';
import 'package:frontend/utils/date_utils.dart';
import 'package:frontend/widgets/user_app_bar.dart';

class BorrowDetailsScreen extends StatefulWidget {
  final int? borrowId;

  const BorrowDetailsScreen({super.key, this.borrowId});

  @override
  State<BorrowDetailsScreen> createState() => _BorrowDetailsScreenState();
}

class _BorrowDetailsScreenState extends State<BorrowDetailsScreen> {
  final _controller = BorrowDetailsController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    final id = widget.borrowId;
    if (id != null) {
      _controller.load(id);
    }
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

  String _displayDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final parsed = AppDateUtils.tryParseYmd(raw);
    return parsed == null ? raw : AppDateUtils.formatDisplay(parsed);
  }

  // แสดง SnackBar หลังกดปุ่ม: err เป็น null แปลว่าสำเร็จ
  void _showResult(String? err, String successMessage) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? successMessage)));
  }

  Future<void> _confirmReturnWithPrompt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm returned item?'),
        content: const Text('Confirm that the item has been returned to you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm return'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await _controller.confirmReturn();
    _showResult(err, 'Return confirmed');
  }

  Future<void> _cancelRequest(BorrowModel borrow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel borrow request?'),
        content: const Text(
          'Any payment for this request will be refunded to your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = await _controller.cancelRequest();
    _showResult(token, 'Request cancelled');
  }

  Future<void> _payNow(BorrowModel borrow) async {
    await Navigator.pushNamed(
      context,
      '/payment',
      arguments: {'borrowId': borrow.id},
    );
    if (mounted) await _controller.load(borrow.id);
  }

  @override
  Widget build(BuildContext context) {
    final borrow = _controller.borrow;

    return Scaffold(
      appBar: const UserAppBar(title: 'Borrow Details'),
      body: widget.borrowId == null
          ? const Center(child: Text('No borrow selected'))
          : _controller.loading && borrow == null
          ? const Center(child: CircularProgressIndicator())
          : borrow == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _controller.error ?? 'Borrow not found',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _controller.load(widget.borrowId!),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _buildContent(borrow),
    );
  }

  Widget _buildContent(BorrowModel borrow) {
    final steps = _controller.timeline;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((borrow.status == 'requested' || borrow.status == 'approved') &&
              borrow.paymentStatus == 'unpaid') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _payNow(borrow),
                child: const Text('Pay now'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelRequest(borrow),
                child: const Text('Cancel request'),
              ),
            ),
          ] else if ((borrow.status == 'requested' ||
                  borrow.status == 'approved') &&
              borrow.paymentStatus == 'paid') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelRequest(borrow),
                child: const Text('Cancel request'),
              ),
            ),
          ],
          // Status timeline อยู่บนสุด
          const Text(
            'Status timeline',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    _TimelineStep(
                      BorrowDetailsController.timelineLabels[i],
                      state: steps[i],
                    ),
                ],
              ),
            ),
          ),
          // จ่ายเงินแล้วแต่ยังไม่ได้รับของ: ปุ่ม Received (เหลือง) กดแล้วขั้น Received เป็นสีเขียว
          if (_controller.canConfirmReceived) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 252, 252, 75),
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final err = await _controller.confirmReceived();
                  _showResult(err, 'Receipt confirmed');
                },
                child: const Text('Received'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      borrow.assetName ?? 'Item',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Rental ID: ${borrow.id}'),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  borrow.statusLabel.isNotEmpty ? borrow.statusLabel : 'Status',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFFFFF9C4),
            child: ListTile(
              leading: const Icon(Icons.event_repeat),
              title: const Text('Return date'),
              subtitle: Text(_displayDate(borrow.plannedReturnDate)),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Lender'),
                  subtitle: Text(borrow.ownerName ?? '—'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Pickup location'),
                  subtitle: Text(
                    borrow.pickupPoint?.isNotEmpty == true
                        ? borrow.pickupPoint!
                        : '—',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Pickup date'),
                  subtitle: Text(_displayDate(borrow.pickupDate)),
                ),
                ListTile(
                  title: Text('Rental fee (${borrow.rentalDays} day(s))'),
                  trailing: Text('${borrow.rentalSubtotal ?? '—'} Baht'),
                ),
                ListTile(
                  title: const Text('Deposit'),
                  trailing: Text('${borrow.deposit ?? '—'} Baht'),
                ),
                ListTile(
                  title: const Text('Total paid'),
                  trailing: Text(
                    '${borrow.totalAmount ?? '—'} Baht',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: const Text('Payment'),
                  trailing: Text(borrow.paymentStatus),
                ),
              ],
            ),
          ),
          if (borrow.status == 'borrowed') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final err = await _controller.requestReturn();
                  _showResult(err, 'Return requested');
                },
                child: const Text('Request return'),
              ),
            ),
          ],
          if (borrow.status == 'returned_pending') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmReturnWithPrompt,
                child: const Text('Confirm return'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (_) => false),
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }
}

// หนึ่งขั้นใน timeline: เขียว = เสร็จแล้ว, เหลือง = กำลังดำเนินการ, เทา = ยังไม่ถึง
class _TimelineStep extends StatelessWidget {
  final String label;
  final TimelineStepState state;

  const _TimelineStep(this.label, {required this.state});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (state) {
      case TimelineStepState.done:
        color = const Color.fromARGB(255, 72, 230, 83);
      case TimelineStepState.inProgress:
        color = const Color.fromARGB(255, 252, 252, 75);
      case TimelineStepState.notStarted:
        color = Colors.grey.shade300;
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26),
          ),
          child: state == TimelineStepState.done
              ? const Icon(Icons.check, size: 18, color: Colors.black87)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

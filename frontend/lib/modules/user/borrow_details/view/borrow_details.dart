import 'package:flutter/material.dart';

import 'package:frontend/modules/user/borrow_details/controller/borrow_details_controller.dart';
import 'package:frontend/utils/date_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    final borrow = _controller.borrow;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Details')),
      body: widget.borrowId == null
          ? const Center(child: Text('No borrow selected'))
          : _controller.loading && borrow == null
              ? const Center(child: CircularProgressIndicator())
              : _controller.error != null && borrow == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _controller.error!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  _controller.load(widget.borrowId!),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      borrow?.assetName ?? 'Item',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('Rental ID: ${borrow?.id ?? '—'}'),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  borrow?.status.isNotEmpty == true
                                      ? borrow!.status
                                      : 'Status',
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
                              subtitle: Text(
                                _displayDate(borrow?.plannedReturnDate),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  title: const Text('Lender'),
                                  subtitle: Text(borrow?.ownerName ?? '—'),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  title: const Text('Pickup location'),
                                  subtitle: Text(
                                    borrow?.pickupPoint?.isNotEmpty == true
                                        ? borrow!.pickupPoint!
                                        : '—',
                                  ),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  title: const Text('Pickup date'),
                                  subtitle: Text(
                                    _displayDate(borrow?.pickupDate),
                                  ),
                                ),
                                ListTile(
                                  title: Text(
                                    'Rental fee (${borrow?.rentalDays ?? 0} day(s))',
                                  ),
                                  trailing: Text(
                                    '${borrow?.rentalSubtotal ?? '—'} Baht',
                                  ),
                                ),
                                ListTile(
                                  title: const Text('Deposit'),
                                  trailing: Text(
                                    '${borrow?.deposit ?? '—'} Baht',
                                  ),
                                ),
                                ListTile(
                                  title: const Text('Total paid'),
                                  trailing: Text(
                                    '${borrow?.totalAmount ?? '—'} Baht',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  title: const Text('Payment'),
                                  trailing: Text(
                                    borrow?.paymentStatus ?? '—',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Status timeline',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _TimelineStep(
                                    'Paid',
                                    active: borrow?.paymentStatus == 'paid' ||
                                        borrow?.paymentStatus == 'refunded',
                                  ),
                                  _TimelineStep(
                                    'Borrowed',
                                    active: borrow?.status == 'borrowed' ||
                                        borrow?.status == 'returned_pending' ||
                                        borrow?.status == 'returned_confirmed',
                                  ),
                                  _TimelineStep(
                                    'Return pending',
                                    active:
                                        borrow?.status == 'returned_pending' ||
                                            borrow?.status ==
                                                'returned_confirmed',
                                  ),
                                  _TimelineStep(
                                    'Returned',
                                    active: borrow?.status ==
                                        'returned_confirmed',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (borrow?.status == 'borrowed') ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final err = await _controller.requestReturn();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(err ?? 'Return requested'),
                                    ),
                                  );
                                },
                                child: const Text('Request return'),
                              ),
                            ),
                          ],
                          if (borrow?.status == 'returned_pending') ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final err = await _controller.confirmReturn();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(err ?? 'Return confirmed'),
                                    ),
                                  );
                                },
                                child: const Text('Confirm return'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context)
                                  .pushNamedAndRemoveUntil(
                                '/home',
                                (_) => false,
                              ),
                              child: const Text('Back to Home'),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool active;

  const _TimelineStep(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            color: active ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );
}

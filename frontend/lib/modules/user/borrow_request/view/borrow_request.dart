import 'package:flutter/material.dart';

import 'package:frontend/modules/user/borrow_request/controller/borrow_request_controller.dart';
import 'package:frontend/utils/date_utils.dart';
import 'package:frontend/widgets/date_picker_field.dart';

class BorrowRequestScreen extends StatefulWidget {
  final int? assetId;

  const BorrowRequestScreen({super.key, this.assetId});

  @override
  State<BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<BorrowRequestScreen> {
  final BorrowRequestController _controller = BorrowRequestController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    final id = widget.assetId;
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

  Future<void> _continue() async {
    final borrow = await _controller.submitRequest();
    if (!mounted) return;

    if (borrow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.error ??
                'Choose pickup and return dates within the lender timeframe',
          ),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'borrowId': borrow.id,
        'assetId': borrow.assetId,
        'pickupDate': borrow.pickupDate,
        'returnDate': borrow.plannedReturnDate,
        'days': borrow.rentalDays,
        'pricePerDay': borrow.pricePerDay ?? _controller.asset?.price,
        'rentalSubtotal': borrow.rentalSubtotal ?? _controller.rentalSubtotal,
        'deposit': borrow.deposit ?? _controller.deposit,
        'total': borrow.totalAmount ?? _controller.total,
        'lendingEndDate': borrow.lendingEndDate,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = _controller.asset;
    final end = _controller.lendingEndDate;
    final today = _controller.earliestPickup;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Request')),
      body: widget.assetId == null
          ? const Center(child: Text('No item selected'))
          : _controller.loading && asset == null
              ? const Center(child: CircularProgressIndicator())
              : _controller.error != null && asset == null
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
                                  _controller.load(widget.assetId!),
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
                          Card(
                            child: ListTile(
                              title: Text(asset?.name ?? 'Item'),
                              subtitle: Text(
                                'Owner: ${asset?.ownerUsername ?? '—'}\n'
                                'Pickup: ${asset?.pickupPoint.isNotEmpty == true ? asset!.pickupPoint : '—'}\n'
                                'Lending end date: ${end == null ? '—' : AppDateUtils.formatDisplay(end)}',
                              ),
                              isThreeLine: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Select dates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            end == null
                                ? 'Lending end date is unavailable for this item.'
                                : 'Dates must stay between ${AppDateUtils.formatDisplay(today)} and ${AppDateUtils.formatDisplay(end)}.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DatePickerField(
                                  label: 'Pickup date',
                                  hintText: 'Select date',
                                  value: _controller.pickupDate,
                                  firstDate: today,
                                  lastDate: end ?? today,
                                  enabled:
                                      end != null && !_controller.submitting,
                                  onPicked: _controller.setPickupDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DatePickerField(
                                  label: 'Return date',
                                  hintText: 'Select date',
                                  value: _controller.returnDate,
                                  firstDate:
                                      _controller.pickupDate ?? today,
                                  lastDate: end ?? today,
                                  enabled: end != null &&
                                      _controller.pickupDate != null &&
                                      !_controller.submitting,
                                  onPicked: _controller.setReturnDate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Price / day: ${asset?.price ?? '—'} Baht',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Days: ${_controller.rentalDayCount == 0 ? '—' : _controller.rentalDayCount}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rental: ${_controller.rentalDayCount == 0 ? '—' : '${_controller.rentalSubtotal} Baht'}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Deposit: ${asset?.downPayment ?? '—'} Baht',
                                  ),
                                  const Divider(height: 24),
                                  Text(
                                    'Total: ${_controller.datesValid ? '${_controller.total} Baht' : '—'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _controller.datesValid &&
                                      !_controller.submitting
                                  ? _continue
                                  : null,
                              child: Text(
                                _controller.submitting
                                    ? 'Submitting...'
                                    : 'Continue to payment',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

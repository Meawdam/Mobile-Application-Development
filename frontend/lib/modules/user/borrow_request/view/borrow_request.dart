import 'package:flutter/material.dart';

class BorrowRequestScreen extends StatefulWidget {
  final String itemId;

  const BorrowRequestScreen({super.key, required this.itemId});

  @override
  State<BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<BorrowRequestScreen> {
  DateTime? _pickupDate;
  DateTime? _returnDate;

  Future<void> _selectDate({required bool pickup}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = pickup ? today : (_pickupDate ?? today);
    final selected = await showDatePicker(
      context: context,
      initialDate: pickup ? (_pickupDate ?? start) : (_returnDate ?? start),
      firstDate: start,
      lastDate: start.add(const Duration(days: 60)),
    );
    if (selected == null) return;
    setState(() {
      if (pickup) {
        _pickupDate = selected;
        if (_returnDate != null && _returnDate!.isBefore(selected)) {
          _returnDate = null;
        }
      } else {
        _returnDate = selected;
      }
    });
  }

  String _format(DateTime? date) =>
      date == null ? 'Select date' : '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final days = _pickupDate != null && _returnDate != null
        ? _returnDate!.difference(_pickupDate!).inDays + 1
        : 0;
    final total = days * 120 + 1500;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              child: ListTile(
                title: Text('Canon M50 Camera'),
                subtitle: Text(
                  'Owner: Somchai Jaidee\nPickup: Central Canteen, Building 3',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select dates',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(pickup: true),
                    child: Text('Pickup\n${_format(_pickupDate)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(pickup: false),
                    child: Text('Return\n${_format(_returnDate)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Price / day: ฿120'),
                    SizedBox(height: 8),
                    Text('Deposit: ฿1,500'),
                  ],
                ),
              ),
            ),
            if (days > 0) ...[
              const SizedBox(height: 12),
              Text('Total for $days days: ฿$total'),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/payment'),
                child: Text(
                  days > 0 ? 'Continue to payment · ฿$total' : 'Select dates',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

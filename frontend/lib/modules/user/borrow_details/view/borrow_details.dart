import 'package:flutter/material.dart';

class BorrowDetailsScreen extends StatelessWidget {
  final String recordId;

  const BorrowDetailsScreen({super.key, this.recordId = 'BR-69-0142'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portable Projector',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Rental ID: BR-69-0142'),
                    ],
                  ),
                ),
                Chip(label: Text('Borrowed')),
              ],
            ),
            const SizedBox(height: 16),
            const Card(
              color: Color(0xFFFFF9C4),
              child: ListTile(
                leading: Icon(Icons.event_repeat),
                title: Text('Return date'),
                subtitle: Text('3/11/2026 · 16:00 · 2 days remaining'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Lender'),
                    subtitle: Text('Somchai Jaidee · 08X-XXX-XXXX'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Pickup location'),
                    subtitle: Text('Central Canteen, Building 3'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Rental fee'),
                    trailing: Text('฿500 paid'),
                  ),
                  ListTile(
                    title: Text('Deposit'),
                    trailing: Text('฿1,000 held'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status timeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TimelineStep('Paid', true),
                    _TimelineStep('Received', true),
                    _TimelineStep('Borrowed', true),
                    _TimelineStep('Returned', false),
                  ],
                ),
              ),
            ),
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
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool complete;

  const _TimelineStep(this.label, this.complete);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(
        complete ? Icons.check_circle : Icons.radio_button_unchecked,
        color: complete ? Colors.green : Colors.grey,
      ),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

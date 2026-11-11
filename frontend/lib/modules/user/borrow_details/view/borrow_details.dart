import 'package:flutter/material.dart';

class BorrowDetailsScreen extends StatelessWidget {
  const BorrowDetailsScreen({super.key});

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
                        'Item Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Rental ID: —'),
                    ],
                  ),
                ),
                Chip(label: Text('Status')),
              ],
            ),
            const SizedBox(height: 16),
            const Card(
              color: Color(0xFFFFF9C4),
              child: ListTile(
                leading: Icon(Icons.event_repeat),
                title: Text('Return date'),
                subtitle: Text('—'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Column(
                children: [
                  ListTile(title: Text('Lender'), subtitle: Text('—')),
                  Divider(height: 1),
                  ListTile(title: Text('Pickup location'), subtitle: Text('—')),
                  Divider(height: 1),
                  ListTile(title: Text('Rental fee'), trailing: Text('—')),
                  ListTile(title: Text('Deposit'), trailing: Text('—')),
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
                    _TimelineStep('Paid'),
                    _TimelineStep('Received'),
                    _TimelineStep('Borrowed'),
                    _TimelineStep('Returned'),
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

  const _TimelineStep(this.label);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

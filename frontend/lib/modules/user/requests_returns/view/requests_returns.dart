import 'package:flutter/material.dart';

class RequestsReturnsScreen extends StatelessWidget {
  const RequestsReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requests & Returns')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Waiting for Response 1',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          const _RequestCard(),
          const SizedBox(height: 24),
          const Text(
            'Borrowed Items 1',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _BorrowedItemCard(
            onConfirm: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const _ConfirmReturnSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('K')),
            title: Text('Kanokwan P. · Business Admin Faculty'),
            subtitle: Text('Request to borrow Canon M50'),
          ),
          Text('9 - 11 Nov 2026 (2 days) · Paid ฿1,740'),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: null, child: Text('Decline')),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(onPressed: null, child: Text('Accept')),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BorrowedItemCard extends StatelessWidget {
  final VoidCallback onConfirm;

  const _BorrowedItemCard({required this.onConfirm});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('S')),
            title: Text('Supachai L. · Science Faculty'),
            subtitle: Text('Portable Projector · Return 3 Nov 2026'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Held deposit'),
            trailing: Text('฿1,000'),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm Item Returned'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ConfirmReturnSheet extends StatelessWidget {
  const _ConfirmReturnSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm item received back',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Portable Projector · Borrower Supachai L.'),
          const SizedBox(height: 10),
          const Text('UI preview only. Return data is not connected.'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    ),
  );
}

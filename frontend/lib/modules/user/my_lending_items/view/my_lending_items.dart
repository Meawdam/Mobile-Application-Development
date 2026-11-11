import 'package:flutter/material.dart';

class MyLendingItemsScreen extends StatelessWidget {
  const MyLendingItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Lending Items')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Total 2 items'),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFE8EEFF),
            child: ListTile(
              leading: const CircleAvatar(child: Text('2')),
              title: const Text('Requests & Returns'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/requests-returns'),
            ),
          ),
          const SizedBox(height: 12),
          _LendingItemCard(
            name: 'Canon M50 Camera',
            price: '฿120/day · Deposit ฿1,500',
            status: 'Available to lend',
            onEdit: () =>
                Navigator.pushNamed(context, '/edit-item', arguments: 'ast-01'),
            onDelete: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const _DeleteItemSheet(),
            ),
          ),
          _LendingItemCard(
            name: 'Portable Projector',
            price: '฿250/day · Deposit ฿1,000',
            status: 'Borrowed · Due 3 Nov',
            onEdit: null,
            onDelete: null,
          ),
          _LendingItemCard(
            name: 'Lab Coat Size M',
            price: '฿50/day · Deposit ฿300',
            status: 'Waiting for admin approval',
            onEdit: null,
            onDelete: null,
          ),
        ],
      ),
    );
  }
}

class _LendingItemCard extends StatelessWidget {
  final String name;
  final String price;
  final String status;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _LendingItemCard({
    required this.name,
    required this.price,
    required this.status,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.image)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(price),
                    Text(status, style: const TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onEdit,
                      child: const Text('Edit'),
                    ),
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 12),
                if (onDelete != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDelete,
                      child: const Text('Unlend'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _DeleteItemSheet extends StatelessWidget {
  const _DeleteItemSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remove this item from the list?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('UI preview only. Item data is not connected.'),
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

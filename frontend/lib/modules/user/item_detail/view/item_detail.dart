import 'package:flutter/material.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: ColoredBox(
                        color: Color(0xFFE8ECF4),
                        child: Icon(Icons.image, size: 64),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Chip(
                        label: Text('Status'),
                        backgroundColor: Color(0xFFE6F4EA),
                      ),
                      SizedBox(width: 8),
                      Text('Condition'),
                    ],
                  ),
                  const Text(
                    'Item Name',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Item description'),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(
                        child: _DetailCard(label: 'Price / day', value: '—'),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _DetailCard(label: 'Deposit', value: '—'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.location_on_outlined),
                    title: Text('Pickup & return location'),
                    subtitle: Text('—'),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Owner'),
                    subtitle: Text('—'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/borrow-request'),
                child: const Text('Request to borrow'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;

  const _DetailCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

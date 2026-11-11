import 'package:flutter/material.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canon M50 Camera')),
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
                        label: Text('Available'),
                        backgroundColor: Color(0xFFE6F4EA),
                      ),
                      SizedBox(width: 8),
                      Text('Good condition'),
                    ],
                  ),
                  const Text(
                    'Canon M50 Camera',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Camera in good condition, includes one lens.'),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(
                        child: _PriceCard(label: 'Price / day', value: '฿120'),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _PriceCard(label: 'Deposit', value: '฿1,500'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.location_on_outlined),
                    title: Text('Pickup & return location'),
                    subtitle: Text('Central Canteen, Building 3'),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Somchai Jaidee'),
                    subtitle: Text('Engineering Faculty · Verified'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '฿120 / day + deposit ฿1,500',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/borrow-request',
                    arguments: itemId,
                  ),
                  child: const Text('Request to borrow'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final String value;

  const _PriceCard({required this.label, required this.value});

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

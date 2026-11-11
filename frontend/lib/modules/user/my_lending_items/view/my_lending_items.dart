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
          Card(
            color: const Color(0xFFE8EEFF),
            child: ListTile(
              title: const Text('Requests & Returns'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/requests-returns'),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No items to display'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-item'),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello'),
                      SizedBox(height: 4),
                      Text(
                        'What would you like to borrow?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Wallet',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/wallet'),
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                      ),
                      IconButton(
                        tooltip: 'Log out',
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (_) => false),
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search items',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Add item',
                    onPressed: () => Navigator.pushNamed(context, '/add-item'),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Items available to borrow',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No items to display'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

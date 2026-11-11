import 'package:flutter/material.dart';

class RequestsReturnsScreen extends StatelessWidget {
  const RequestsReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requests & Returns')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Waiting for Response',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 12),
          _EmptySection(),
          SizedBox(height: 24),
          Text(
            'Borrowed Items',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 12),
          _EmptySection(),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection();

  @override
  Widget build(BuildContext context) => const Card(
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No items to display')),
      ),
    ),
  );
}

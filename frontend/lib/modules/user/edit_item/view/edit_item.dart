import 'package:flutter/material.dart';

class EditItemScreen extends StatelessWidget {
  const EditItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                height: 160,
                width: double.infinity,
                child: ColoredBox(
                  color: Color(0xFFE8ECF4),
                  child: Icon(Icons.image, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Canon M50 Camera',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              enabled: false,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Item Details & Condition',
                hintText: 'Condition, accessories included, or important notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (Baht / Day)',
                hintText: 'e.g. 120',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Deposit (Baht)',
                hintText: 'e.g. 1500',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Pickup & return location',
                hintText: 'e.g., Central Canteen, Building 3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Return date',
                hintText: 'Select date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                child: Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

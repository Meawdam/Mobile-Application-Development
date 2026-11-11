import 'package:flutter/material.dart';

class EditItemScreen extends StatefulWidget {
  final String itemId;

  const EditItemScreen({super.key, required this.itemId});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  DateTime? _availableUntil = DateTime(2026, 12, 31);

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _availableUntil!.isAfter(today)
          ? _availableUntil!
          : today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (date != null) setState(() => _availableUntil = date);
  }

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
                hintText: 'Canon M50 Camera',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              enabled: false,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Item Details & Condition',
                hintText: 'Good condition, includes accessories',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (Baht / Day)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Deposit (Baht)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Pickup & return location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Return date'),
              subtitle: Text(
                '${_availableUntil!.day}/${_availableUntil!.month}/${_availableUntil!.year}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            const Text('UI preview only'),
          ],
        ),
      ),
    );
  }
}

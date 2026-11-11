import 'package:flutter/material.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  DateTime? _availableUntil;

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _availableUntil ?? today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (date != null) setState(() => _availableUntil = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Borrowing Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40),
                  SizedBox(height: 6),
                  Text('Add Photo (Only 1 image supported)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: _decoration('Item Name', 'e.g., Canon M50 Camera'),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: _decoration(
                'Item Details & Condition',
                'Condition, accessories included, or important notes',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Price (Baht / Day)', 'e.g. 120'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Deposit (Baht)', 'e.g. 1500'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 2,
              decoration: _decoration(
                'Pickup & return location',
                'e.g., Central Canteen, Building 3',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: _decoration('Lending end date', null).copyWith(
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _availableUntil == null
                      ? 'Select date'
                      : '${_availableUntil!.day}/${_availableUntil!.month}/${_availableUntil!.year}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                child: const Text('Submit for Admin Approval'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('UI preview only')),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, String? hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

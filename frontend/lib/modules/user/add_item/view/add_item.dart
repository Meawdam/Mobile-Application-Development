import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/modules/user/add_item/controller/add_item_controller.dart';
import 'package:frontend/utils/date_utils.dart';
import 'package:frontend/widgets/date_picker_field.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _controller = AddItemController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _pickupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await _controller.submit(
      name: _nameController.text,
      description: _descriptionController.text,
      price: _priceController.text,
      deposit: _depositController.text,
      pickupPoint: _pickupController.text,
    );

    if (!mounted) return;

    final message = switch (result) {
      AddItemResult.success =>
        'Item submitted for admin approval',
      AddItemResult.missingFields => 'Please complete all fields',
      AddItemResult.missingImage => 'Please add a photo',
      AddItemResult.missingLendingEndDate =>
        'Please choose a lending end date',
      AddItemResult.invalidPrice => 'Price must be a whole number',
      AddItemResult.invalidDeposit => 'Deposit must be a valid number',
      AddItemResult.failed =>
        _controller.error ?? 'Unable to submit item',
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (result == AddItemResult.success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.today();
    final lastSelectable = today.add(const Duration(days: 365 * 2));

    return Scaffold(
      appBar: AppBar(title: const Text('Add Borrowing Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _controller.submitting ? null : _controller.pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  image: _controller.imageBytes == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(_controller.imageBytes!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _controller.imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40),
                          SizedBox(height: 6),
                          Text('Add Photo'),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Canon M50 Camera',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Item Details & Condition',
                hintText: 'Condition, accessories included, or important notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Price (Baht / Day)',
                      hintText: 'e.g. 120',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _depositController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Deposit (Baht)',
                      hintText: 'e.g. 1500',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pickupController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Pickup & return location',
                hintText: 'e.g., Central Canteen, Building 3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DatePickerField(
              label: 'Lending end date',
              hintText: 'Select date',
              value: _controller.lendingEndDate,
              firstDate: today,
              lastDate: lastSelectable,
              showCalendarIcon: true,
              enabled: !_controller.submitting,
              onPicked: _controller.setLendingEndDate,
            ),
            if (_controller.lendingEndDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Borrowers can pick dates from today through ${AppDateUtils.formatDisplay(_controller.lendingEndDate!)}.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _controller.submitting ? null : _submit,
                child: Text(
                  _controller.submitting
                      ? 'Submitting...'
                      : 'Submit for Admin Approval',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

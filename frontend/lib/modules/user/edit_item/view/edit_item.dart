import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/modules/user/edit_item/controller/edit_item_controller.dart';
import 'package:frontend/utils/date_utils.dart';
import 'package:frontend/widgets/date_picker_field.dart';

class EditItemScreen extends StatefulWidget {
  final int? assetId;

  const EditItemScreen({super.key, this.assetId});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _controller = EditItemController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _pickupController = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    final id = widget.assetId;
    if (id != null) {
      _controller.load(id);
    }
  }

  void _onUpdate() {
    final asset = _controller.asset;
    if (!_filled && asset != null) {
      _nameController.text = asset.name;
      _descriptionController.text = asset.description;
      _priceController.text = asset.price.toString();
      _depositController.text = asset.downPayment.toString();
      _pickupController.text = asset.pickupPoint;
      _filled = true;
    }
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

  Future<void> _save() async {
    final result = await _controller.save(
      name: _nameController.text,
      description: _descriptionController.text,
      price: _priceController.text,
      deposit: _depositController.text,
      pickupPoint: _pickupController.text,
    );
    if (!mounted) return;

    final message = switch (result) {
      EditItemResult.success => 'Changes saved',
      EditItemResult.missingFields => 'Please complete all fields',
      EditItemResult.missingLendingEndDate => 'Please choose a lending end date',
      EditItemResult.invalidPrice => 'Price must be a whole number',
      EditItemResult.invalidDeposit => 'Deposit must be a valid number',
      EditItemResult.failed => _controller.error ?? 'Unable to save changes',
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (result == EditItemResult.success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.today();
    final lastSelectable = today.add(const Duration(days: 365 * 2));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: widget.assetId == null
          ? const Center(child: Text('No item selected'))
          : _controller.loading && _controller.asset == null
              ? const Center(child: CircularProgressIndicator())
              : _controller.error != null && _controller.asset == null
                  ? Center(child: Text(_controller.error!))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 160,
                              width: double.infinity,
                              child: _controller.asset?.imageUrl.isNotEmpty == true
                                  ? Image.network(
                                      _controller.asset!.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const ColoredBox(
                                        color: Color(0xFFE8ECF4),
                                        child: Icon(Icons.broken_image_outlined),
                                      ),
                                    )
                                  : const ColoredBox(
                                      color: Color(0xFFE8ECF4),
                                      child: Icon(Icons.image, size: 48),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Item Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Item Details & Condition',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Price (Baht / Day)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _depositController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Deposit (Baht)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pickupController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Pickup & return location',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DatePickerField(
                            label: 'Lending end date',
                            value: _controller.lendingEndDate,
                            firstDate: today,
                            lastDate: lastSelectable,
                            showCalendarIcon: true,
                            enabled: !_controller.submitting,
                            onPicked: _controller.setLendingEndDate,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _controller.submitting ? null : _save,
                              child: Text(
                                _controller.submitting
                                    ? 'Saving...'
                                    : 'Save changes',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

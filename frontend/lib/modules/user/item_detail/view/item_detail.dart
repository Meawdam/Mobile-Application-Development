import 'package:flutter/material.dart';

import 'package:frontend/modules/user/item_detail/controller/item_detail_controller.dart';

class ItemDetailScreen extends StatefulWidget {
  final int? assetId;

  const ItemDetailScreen({super.key, this.assetId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ItemDetailController _controller = ItemDetailController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    final id = widget.assetId;
    if (id != null) {
      _controller.load(id);
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _controller.asset;

    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: widget.assetId == null
          ? const Center(child: Text('No item selected'))
          : _controller.loading && asset == null
              ? const Center(child: CircularProgressIndicator())
              : _controller.error != null && asset == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _controller.error!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  _controller.load(widget.assetId!),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    height: 220,
                                    width: double.infinity,
                                    child: asset!.imageUrl.isEmpty
                                        ? const ColoredBox(
                                            color: Color(0xFFE8ECF4),
                                            child: Icon(Icons.image, size: 64),
                                          )
                                        : Image.network(
                                            asset.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const ColoredBox(
                                              color: Color(0xFFE8ECF4),
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                size: 64,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(_statusLabel(asset.status)),
                                      backgroundColor: const Color(0xFFE6F4EA),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      asset.returnBefore.isEmpty
                                          ? 'Available'
                                          : 'Until ${asset.returnBefore}',
                                    ),
                                  ],
                                ),
                                Text(
                                  asset.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  asset.description.isEmpty
                                      ? 'No description'
                                      : asset.description,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DetailCard(
                                        label: 'Price / day',
                                        value: '${asset.price} Baht',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DetailCard(
                                        label: 'Deposit',
                                        value: '${asset.downPayment} Baht',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  title: const Text(
                                    'Pickup & return location',
                                  ),
                                  subtitle: Text(
                                    asset.pickupPoint.isEmpty
                                        ? '—'
                                        : asset.pickupPoint,
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: const Text('Owner'),
                                  subtitle: Text(
                                    asset.ownerUsername?.isNotEmpty == true
                                        ? asset.ownerUsername!
                                        : 'User #${asset.ownerId}',
                                  ),
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
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/borrow-request',
                                arguments: asset.id,
                              ),
                              child: const Text('Request to borrow'),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Status';
    return '${status[0].toUpperCase()}${status.substring(1)}';
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

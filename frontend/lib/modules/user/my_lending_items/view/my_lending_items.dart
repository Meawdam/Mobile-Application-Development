import 'package:flutter/material.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/utils/date_utils.dart';

class MyLendingItemsScreen extends StatefulWidget {
  const MyLendingItemsScreen({super.key});

  @override
  State<MyLendingItemsScreen> createState() => _MyLendingItemsScreenState();
}

class _MyLendingItemsScreenState extends State<MyLendingItemsScreen> {
  final _controller = MyLendingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.load();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showDeleteSheet(AssetModel asset) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Delete "${asset.name}"?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('This cannot be undone.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete item'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;
    final err = await _controller.deleteAsset(asset.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Item deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lending Items'),
        actions: [
          IconButton(
            onPressed: _controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _controller.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFFE8EEFF),
              child: ListTile(
                title: const Text('Requests & Returns'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, '/requests-returns'),
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(_controller.error!)),
              )
            else if (_controller.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No items to display')),
              )
            else
              ..._controller.items.map((asset) {
                final end = AppDateUtils.tryParseYmd(asset.returnBefore);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: asset.imageUrl.isEmpty
                          ? const Icon(Icons.inventory_2_outlined)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                asset.imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                      title: Text(asset.name),
                      subtitle: Text(
                        'Status: ${asset.status} · ${asset.approval}\n'
                        'Until: ${end == null ? asset.returnBefore : AppDateUtils.formatDisplay(end)}\n'
                        '${asset.price} Baht / day',
                      ),
                      isThreeLine: true,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          '/edit-item',
                          arguments: asset.id,
                        );
                        await _controller.load();
                      },
                      trailing: IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _showDeleteSheet(asset),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/add-item');
                  await _controller.load();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/modules/user/my_lending_items/controller/my_lending_controller.dart';
import 'package:frontend/utils/date_utils.dart';
import 'package:frontend/utils/app_colors.dart';
import 'package:frontend/widgets/app_popup.dart';
import 'package:frontend/widgets/user_app_bar.dart';

class MyLendingItemsScreen extends StatefulWidget {
  /// ใส่ controller จากภายนอกได้ (ใช้ตอนทำ widget test) ถ้าไม่ใส่จะสร้างเอง
  final MyLendingController? controller;

  const MyLendingItemsScreen({super.key, this.controller});

  @override
  State<MyLendingItemsScreen> createState() => _MyLendingItemsScreenState();
}

class _MyLendingItemsScreenState extends State<MyLendingItemsScreen> {
  late final MyLendingController _controller =
      widget.controller ?? MyLendingController();

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
    final confirmed = await showAppConfirmPopup(
      context,
      title: 'Delete "${asset.name}"?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete item',
    );

    if (!confirmed) return;
    final err = await _controller.deleteAsset(asset.id);
    if (!mounted) return;
    await showAppPopup(
      context,
      message: err ?? 'Item deleted',
      isSuccess: err == null,
    );
  }

  Future<void> _toggleListing(AssetModel asset) async {
    final makeAvailable = asset.status == 'unavailable';
    final confirmed = await showAppConfirmPopup(
      context,
      title: makeAvailable ? 'Relist "${asset.name}"?' : 'Pause listing?',
      message: makeAvailable
          ? 'Borrowers will be able to request this item again.'
          : 'Borrowers will no longer see this item as available.',
      confirmLabel: makeAvailable ? 'Relist item' : 'Pause listing',
    );
    if (!confirmed) return;
    final err = await _controller.setAvailability(asset.id, makeAvailable);
    if (!mounted) return;
    await showAppPopup(
      context,
      message: err ?? (makeAvailable ? 'Item relisted' : 'Listing paused'),
      isSuccess: err == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserAppBar(
        title: 'My Lending Items',
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
                onTap: () => Navigator.pushNamed(context, '/requests-returns'),
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
                final notApproved = asset.approval == 'not approve';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      minLeadingWidth: 60,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 60,
                          height: 64,
                          child: asset.imageUrl.isEmpty
                              ? const ColoredBox(
                                  color: Color(0xFFE8ECF4),
                                  child: Icon(Icons.inventory_2_outlined),
                                )
                              : Image.network(
                                  _imageSrc(asset.imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const ColoredBox(
                                        color: Color(0xFFE8ECF4),
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      ),
                                ),
                        ),
                      ),
                      title: Text(
                        asset.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AssetStatusBadge(
                              label: _statusLabel(asset),
                              color: _statusColor(asset),
                              foreground: _statusForeground(asset),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ImportantValue(
                                    label: 'PRICE / DAY',
                                    value: '${asset.price} Baht',
                                    icon: Icons.payments_outlined,
                                    color: const Color(0xFF166534),
                                    background: const Color(0xFFDCFCE7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ImportantValue(
                                    label: 'LENDING UNTIL',
                                    value: end == null
                                        ? asset.returnBefore
                                        : AppDateUtils.formatDisplay(end),
                                    icon: Icons.event_outlined,
                                    color: const Color(0xFF1D4ED8),
                                    background: const Color(0xFFDBEAFE),
                                  ),
                                ),
                              ],
                            ),
                            if (notApproved) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Text(
                                  'Admin reason: ${asset.approvalMessage?.trim().isNotEmpty == true ? asset.approvalMessage : 'No reason provided.'}',
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      isThreeLine: true,
                      onTap: notApproved
                          ? null
                          : () async {
                              await Navigator.pushNamed(
                                context,
                                '/edit-item',
                                arguments: asset.id,
                              );
                              await _controller.load();
                            },
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Item actions',
                        onSelected: (action) => action == 'delete'
                            ? _showDeleteSheet(asset)
                            : _toggleListing(asset),
                        itemBuilder: (context) => [
                          if (asset.approval == 'approved' &&
                              (asset.status == 'ready' ||
                                  asset.status == 'unavailable'))
                            PopupMenuItem(
                              value: 'availability',
                              child: Text(
                                asset.status == 'unavailable'
                                    ? 'Relist item'
                                    : 'Pause listing',
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete item'),
                          ),
                        ],
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.blue,
                        ),
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

String _statusLabel(AssetModel asset) {
  if (asset.approval == 'not approve') return 'Not approved';
  if (asset.approval == 'pending') return 'Waiting for admin approval';
  return switch (asset.status) {
    'ready' => 'Ready to lend',
    'borrowed' => 'Currently borrowed',
    'pending' => 'Pending',
    'unavailable' => 'Unavailable',
    _ => asset.status,
  };
}

Color _statusColor(AssetModel asset) {
  if (asset.approval == 'not approve' || asset.status == 'unavailable') {
    return const Color(0xFFFEE2E2);
  }
  if (asset.approval == 'pending' || asset.status == 'pending') {
    return const Color(0xFFFEF3C7);
  }
  if (asset.status == 'borrowed') return const Color(0xFFDBEAFE);
  return const Color(0xFFDCFCE7);
}

Color _statusForeground(AssetModel asset) {
  if (asset.approval == 'not approve' || asset.status == 'unavailable') {
    return const Color(0xFFB42318);
  }
  if (asset.approval == 'pending' || asset.status == 'pending') {
    return const Color(0xFF92400E);
  }
  if (asset.status == 'borrowed') return const Color(0xFF1D4ED8);
  return const Color(0xFF166534);
}

class _AssetStatusBadge extends StatelessWidget {
  const _AssetStatusBadge({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ImportantValue extends StatelessWidget {
  const _ImportantValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backend stores images as relative paths (e.g. /uploads/xxx.jpg);
/// build the full URL here so the image loads directly from the server.
String _imageSrc(String path) =>
    path.startsWith('http') ? path : 'http://localhost:3000$path';

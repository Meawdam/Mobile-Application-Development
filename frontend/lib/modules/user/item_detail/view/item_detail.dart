import 'package:flutter/material.dart';

import 'package:frontend/modules/user/item_detail/controller/item_detail_controller.dart';
import 'package:frontend/widgets/user_app_bar.dart';

class ItemDetailScreen extends StatefulWidget {
  final int? assetId;
  final ItemDetailController? controller;

  const ItemDetailScreen({super.key, this.assetId, this.controller});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final ItemDetailController _controller =
      widget.controller ?? ItemDetailController();

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
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _controller.asset;
    final isAvailable =
        asset != null &&
        (asset.status == 'ready' || asset.status == 'available') &&
        asset.approval == 'approved';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: const UserAppBar(title: 'Item details'),
      body: widget.assetId == null
          ? const _MessageState(
              icon: Icons.inventory_2_outlined,
              title: 'No item selected',
              message: 'Choose an item to see its details.',
            )
          : _controller.loading && asset == null
          ? const _MessageState(
              loading: true,
              title: 'Loading item',
              message: 'Getting the latest item details...',
            )
          : _controller.error != null && asset == null
          ? _MessageState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load this item',
              message: _controller.error!,
              action: OutlinedButton.icon(
                onPressed: () => _controller.load(widget.assetId!),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            )
          : asset == null
          ? const _MessageState(
              icon: Icons.inventory_2_outlined,
              title: 'Item unavailable',
              message: 'The item details could not be found.',
            )
          : RefreshIndicator(
              onRefresh: () => _controller.load(asset.id),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(
                          height: 250,
                          width: double.infinity,
                          child: asset.imageUrl.isEmpty
                              ? const ColoredBox(
                                  color: Color(0xFFE8ECF4),
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 64,
                                    color: Color(0xFF8993A5),
                                  ),
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
                                          color: Color(0xFF8993A5),
                                        ),
                                      ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: [
                            _StatusChip(
                              label: isAvailable ? 'Available' : 'Unavailable',
                              available: isAvailable,
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.event_available_outlined,
                              size: 17,
                              color: Color(0xFF667085),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                asset.returnBefore.isEmpty
                                    ? 'End date not set'
                                    : 'Until ${asset.returnBefore}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          asset.name,
                          style: const TextStyle(
                            color: Color(0xFF17233C),
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          asset.description.isEmpty
                              ? 'No description provided.'
                              : asset.description,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailCard(
                                icon: Icons.payments_outlined,
                                label: 'Rental price',
                                value: '${asset.price} Baht',
                                detail: 'per day',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DetailCard(
                                icon: Icons.security_outlined,
                                label: 'Deposit',
                                value: '${asset.downPayment} Baht',
                                detail: 'refundable',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _InfoTile(
                          icon: Icons.location_on_outlined,
                          title: 'Pickup location',
                          subtitle: asset.pickupPoint.isEmpty
                              ? 'Location not provided'
                              : asset.pickupPoint,
                        ),
                        const SizedBox(height: 8),
                        _InfoTile(
                          icon: Icons.person_outline,
                          title: 'Listed by',
                          subtitle: asset.ownerUsername?.isNotEmpty == true
                              ? asset.ownerUsername!
                              : 'User #${asset.ownerId}',
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: asset == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: FilledButton.icon(
                onPressed: isAvailable
                    ? () => Navigator.pushNamed(
                        context,
                        '/borrow-request',
                        arguments: asset.id,
                      )
                    : null,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  isAvailable ? 'Request to borrow' : 'Not available to borrow',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF3156D8),
                  disabledBackgroundColor: const Color(0xFFCBD1DC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EBF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF3156D8)),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF17233C),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFF8993A5), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.available});

  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available ? const Color(0xFF20845A) : const Color(0xFF667085);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE6F4EA) : const Color(0xFFE9ECF2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3156D8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF8993A5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF17233C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    this.icon = Icons.inventory_2_outlined,
    required this.title,
    required this.message,
    this.loading = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 42, color: const Color(0xFF8993A5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF17233C),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085), height: 1.4),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

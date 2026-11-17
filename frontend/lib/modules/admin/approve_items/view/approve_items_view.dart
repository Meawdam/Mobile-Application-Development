import 'package:flutter/material.dart';
//import 'controller/approve_items_controller.dart';
//import 'model/approve_item_model.dart';
import 'package:frontend/modules/admin/approve_items/controller/approve_items_controller.dart';
import 'package:frontend/modules/admin/approve_items/model/approve_item_model.dart';

class ApproveItemsPage extends StatefulWidget {
  const ApproveItemsPage({super.key});

  @override
  State<ApproveItemsPage> createState() => _ApproveItemsPageState();
}

class _ApproveItemsPageState extends State<ApproveItemsPage> {
  // Team palette (agreed colors only). Do not add new colors without
  // sending the code to the team first.
  static const _blue = Color(0xFF2F4BFF);
  static const _red = Color.fromARGB(255, 223, 42, 42);
  static const _yellow = Color.fromARGB(255, 252, 252, 75);
  static const _green = Color.fromARGB(255, 72, 230, 83);
  // Dark text for light backgrounds (yellow / green).
  static const _onLight = Color(0xFF172554);
  static const _blueTint = Color(0xFFE8ECFF);

  final TextEditingController noteController = TextEditingController();

  late final ApproveItemsController controller;

  @override
  void initState() {
    super.initState();
    controller = ApproveItemsController();
    controller.addListener(_refresh);
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      await controller.fetchItems();
    } catch (_) {
      // The controller stores the message for display in the page.
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  void _openDetails(ApproveItem item) {
    noteController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Item Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildDetails(item),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    14 + MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _decide(item.id, item.name, false, sheetContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _red,
                            side: const BorderSide(color: _red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _decide(item.id, item.name, true, sheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: _onLight,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetails(ApproveItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: _blueTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 55,
              color: _blue,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _detailRow('Item Name', item.name),
        _detailRow('Owner', item.owner),
        _detailRow('Submitted', item.time),
        _detailRow('Category', item.category),
        _detailRow('Description', item.description),
        const SizedBox(height: 8),
        const Text(
          'Rejection reason (required when rejecting)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter reason for rejection...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
    String itemId,
    String itemName,
    bool approve,
    BuildContext sheetContext,
  ) async {
    final reason = noteController.text.trim();

    if (!approve && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for rejection.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve Item' : 'Reject Item'),
        content: Text(
          approve
              ? 'Are you sure you want to approve "$itemName"?'
              : 'Are you sure you want to reject "$itemName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? _green : _red,
              foregroundColor: approve ? _onLight : Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || !sheetContext.mounted) return;

    final success = approve
        ? await controller.approveItem(itemId)
        : await controller.rejectItem(itemId, reason);

    if (!mounted || !sheetContext.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Unable to process this item.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(sheetContext);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? 'Item approved successfully!'
              : 'Item rejected successfully!',
          style: TextStyle(color: approve ? _onLight : Colors.white),
        ),
        backgroundColor: approve ? _green : _red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = controller.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 4),
              child: Text(
                'Approve Items',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Review and approve submitted items',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending_actions, color: _onLight),
                    const SizedBox(width: 10),
                    const Text(
                      'Pending',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: _yellow,
                      child: Text(
                        '${controller.pendingCount}',
                        style: const TextStyle(
                          color: _onLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: controller.isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : controller.errorMessage != null && items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadItems,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    )
                  : items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 55,
                            color: Color(0xFF1F9D2B),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No pending items',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'All requests have been reviewed.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE5EAF2)),
                          ),
                          child: InkWell(
                            onTap: () => _openDetails(item),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: _blueTint,
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: _blue,
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${item.owner} • ${item.time}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _blueTint,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: const TextStyle(
                                                color: _blue,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

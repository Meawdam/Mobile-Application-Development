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
  bool _reasonError = false;

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
    _reasonError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => SafeArea(
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
                      child: _buildDetails(item, setSheetState),
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
                            onPressed: () => _decide(
                              item.id,
                              item.name,
                              false,
                              sheetContext,
                              setSheetState,
                            ),
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
                            onPressed: () => _decide(
                              item.id,
                              item.name,
                              true,
                              sheetContext,
                              setSheetState,
                            ),
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
          ),
        );
      },
    );
  }

  Widget _buildDetails(ApproveItem item, StateSetter setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 180,
              height: 180,
              child: item.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: _blueTint,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: _blue,
                      ),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: _blueTint,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 56,
                          color: _blue,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _detailRow('Item Name', item.name),
        _detailRow('Owner', item.owner),
        _detailRow('Submitted', item.time),
        _detailRow('Description', item.description),
        const SizedBox(height: 8),
        const Text(
          'Rejection reason',
          style: TextStyle(fontWeight: FontWeight.bold, color: _onLight),
        ),
        const SizedBox(height: 4),
        const Text(
          'Required to reject this item. Explain what needs to be corrected.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          maxLines: 3,
          maxLength: 500,
          onChanged: (_) {
            if (_reasonError && noteController.text.trim().isNotEmpty) {
              setSheetState(() => _reasonError = false);
            }
          },
          decoration: InputDecoration(
            hintText: 'Example: Please add a clear photo of the item label.',
            filled: true,
            fillColor: Colors.white,
            errorText: _reasonError ? 'A rejection reason is required.' : null,
            errorMaxLines: 2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _reasonError ? _red : const Color(0xFFDCE5F2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _reasonError ? _red : _blue,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (_reasonError)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE8E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 18, color: _red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can’t reject this item yet. Enter a reason above so the owner knows what to fix.',
                    style: TextStyle(color: _red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
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
    StateSetter setSheetState,
  ) async {
    final reason = noteController.text.trim();

    if (!approve && reason.isEmpty) {
      setSheetState(() => _reasonError = true);
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
            Container(
              margin: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1E8F2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _blueTint,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: _blue),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approve items',
                          style: TextStyle(
                            fontSize: 21,
                            color: _onLight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Review new listings before they appear to users.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6DF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${controller.pendingCount}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF9A6700),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'PENDING',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: .5,
                            color: Color(0xFF9A6700),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE1E8F2)),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 48,
                              color: Color(0xFF16845B),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'You’re all caught up',
                              style: TextStyle(
                                fontSize: 17,
                                color: _onLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'There are no items waiting for review.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          color: Colors.white,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xFFE1E8F2)),
                          ),
                          child: InkWell(
                            onTap: () => _openDetails(item),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: item.imageUrl.isEmpty
                                          ? const ColoredBox(
                                              color: _blueTint,
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: _blue,
                                              ),
                                            )
                                          : Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const ColoredBox(
                                                    color: _blueTint,
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: _blue,
                                                    ),
                                                  ),
                                            ),
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

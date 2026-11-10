import 'package:flutter/material.dart';

class ApproveItemsPage extends StatefulWidget {
  const ApproveItemsPage({super.key});

  @override
  State<ApproveItemsPage> createState() => _ApproveItemsPageState();
}

class _ApproveItemsPageState extends State<ApproveItemsPage> {
  final TextEditingController noteController = TextEditingController();

  final items = [
    {
      'name': 'Casio fx-991EX Calculator',
      'owner': 'Somchai Jaidee',
      'time': '30 Oct. 11:10',
      'category': 'Calculator',
      'description': 'Scientific calculator for university study.',
    },
    {
      'name': 'Lab Coat Size M',
      'owner': 'Suphaporn K.',
      'time': '29 Oct. 16:08',
      'category': 'Clothing',
      'description': 'White laboratory coat, size M.',
    },
    {
      'name': 'Calculus Textbook Vol. 1',
      'owner': 'Nattapat P.',
      'time': '28 Oct. 09:30',
      'category': 'Book',
      'description': 'Calculus textbook in good condition.',
    },
  ];

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void _openDetails(int index) {
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
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                    child: _buildDetails(items[index]),
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
                            index,
                            false,
                            sheetContext,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _decide(
                            index,
                            true,
                            sheetContext,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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

  Widget _buildDetails(Map<String, String> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 55,
              color: Color(0xFF1260C5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _detailRow('Item Name', item['name']!),
        _detailRow('Owner', item['owner']!),
        _detailRow('Submitted', item['time']!),
        _detailRow('Category', item['category']!),
        _detailRow('Description', item['description']!),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
    int index,
    bool approve,
    BuildContext sheetContext,
  ) async {
    if (!approve && noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason for rejection.'),
        ),
      );
      return;
    }

    final itemName = items[index]['name']!;

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
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      items.removeAt(index);
    });

    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? 'Item approved successfully!'
              : 'Item rejected successfully!',
        ),
        backgroundColor: approve ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0EEEE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Approve Items',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review and approve submitted items',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pending',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 55,
                          color: Colors.green,
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF1260C5),
                            ),
                          ),
                          title: Text(
                            item['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${item['owner']} • ${item['time']}',
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openDetails(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
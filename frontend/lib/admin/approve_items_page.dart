
import 'package:flutter/material.dart';

class ApproveItemsPage extends StatefulWidget {
  const ApproveItemsPage({super.key});

  @override
  State<ApproveItemsPage> createState() => _ApproveItemsPageState();
}

class _ApproveItemsPageState extends State<ApproveItemsPage> {
  final noteController = TextEditingController();

  final items = [
    {'name': 'Calculus Textbook Vol. 1', 'owner': 'Thanakon W.', 'time': 'Today 10:40'},
    {'name': 'Canon M50 Camera', 'owner': 'Natthawut K.', 'time': 'Today 09:05'},
    {'name': 'Bluetooth Speaker', 'owner': 'Phimchanok S.', 'time': 'Yesterday 17:30'},
  ];

  int selectedIndex = 0;
  bool decided = false;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void decide(bool approve) {
    if (!approve && noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason before rejecting.')),
      );
      return;
    }

    setState(() {
      items.removeAt(selectedIndex);
      selectedIndex = items.isEmpty ? -1 : 0;
      noteController.clear();
      decided = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Item approved' : 'Item rejected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItem = selectedIndex >= 0 && selectedIndex < items.length;

    return Container(
      color: const Color(0xFFF0EEEE),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Approve Items',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Text(
            'Items will be displayed on the home page only when approved and status is set to "Available"',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 265,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Text('Pending ${items.length}',
                              style: const TextStyle(
                                  color: Color(0xFF1800A8),
                                  fontWeight: FontWeight.bold)),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Card(
                                  color: selectedIndex == index
                                      ? const Color(0xFFE8F1FF)
                                      : Colors.white,
                                  child: ListTile(
                                    leading: const Icon(Icons.image,
                                        color: Colors.blue),
                                    title: Text(item['name']!,
                                        style: const TextStyle(fontSize: 13)),
                                    subtitle: Text(
                                      '${item['owner']} - ${item['time']}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    onTap: () => setState(() {
                                      selectedIndex = index;
                                      noteController.clear();
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => decided = true),
                            child: const Text('Decided'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: hasItem && !decided
                          ? _detail(items[selectedIndex])
                          : const Center(
                              child: Text('No pending item selected')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(Map<String, String> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item['name']!,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Owner: ${item['owner']} - Submitted ${item['time']}'),
        const SizedBox(height: 20),
        Container(
          height: 110,
          width: 110,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.image, size: 55, color: Colors.blue),
        ),
        const SizedBox(height: 22),
        _info('Details', '1st-year item, good condition, no markings'),
        _info('Rental Fee', '10 ฿ per day'),
        _info('Deposit', '100 ฿'),
        _info('Item Status', 'Pending - Ready upon approval'),
        const SizedBox(height: 18),
        const Text('Reason / Note',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Required when rejecting',
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => decide(false),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => decide(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white),
              child: const Text('Approve'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: Text(value, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

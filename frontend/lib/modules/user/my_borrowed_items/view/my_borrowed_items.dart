import 'package:flutter/material.dart';

class MyBorrowedItemsScreen extends StatefulWidget {
  const MyBorrowedItemsScreen({super.key});

  @override
  State<MyBorrowedItemsScreen> createState() => _MyBorrowedItemsScreenState();
}

class _MyBorrowedItemsScreenState extends State<MyBorrowedItemsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Borrowed Items')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Held deposit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('฿1,000', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Borrowing 1'),
              Tab(text: 'Pending 1'),
              Tab(text: 'Returned 1'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _BorrowList(
                  status: 'Borrowed',
                  itemName: 'Portable Projector',
                  lender: 'Somchai Jaidee',
                  onTap: () => Navigator.pushNamed(context, '/borrow-details'),
                ),
                _BorrowList(
                  status: 'Pending',
                  itemName: 'Canon M50 Camera',
                  lender: 'Kanokwan P.',
                  onTap: () => Navigator.pushNamed(context, '/borrow-details'),
                ),
                _BorrowList(
                  status: 'Returned',
                  itemName: 'Scientific Calculator',
                  lender: 'Nattapat P.',
                  onTap: () => Navigator.pushNamed(context, '/borrow-details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BorrowList extends StatelessWidget {
  final String status;
  final String itemName;
  final String lender;
  final VoidCallback onTap;

  const _BorrowList({
    required this.status,
    required this.itemName,
    required this.lender,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.image)),
          title: Text(itemName),
          subtitle: Text('From $lender\n$status · 2 days remaining'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    ],
  );
}

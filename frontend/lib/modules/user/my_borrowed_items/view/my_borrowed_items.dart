import 'package:flutter/material.dart';

class MyBorrowedItemsScreen extends StatelessWidget {
  const MyBorrowedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
                  Text('—', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Borrowing'),
                Tab(text: 'Pending'),
                Tab(text: 'Returned'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _EmptyBorrowList(),
                  _EmptyBorrowList(),
                  _EmptyBorrowList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBorrowList extends StatelessWidget {
  const _EmptyBorrowList();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('No items to display'));
}

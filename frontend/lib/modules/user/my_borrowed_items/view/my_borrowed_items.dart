import 'package:flutter/material.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/my_borrowed_items/controller/my_borrowed_controller.dart';
import 'package:frontend/utils/date_utils.dart';

class MyBorrowedItemsScreen extends StatefulWidget {
  const MyBorrowedItemsScreen({super.key});

  @override
  State<MyBorrowedItemsScreen> createState() => _MyBorrowedItemsScreenState();
}

class _MyBorrowedItemsScreenState extends State<MyBorrowedItemsScreen> {
  final _controller = MyBorrowedController();

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

  Future<void> _cancel(BorrowModel item) async {
    final err = await _controller.cancel(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Request cancelled')),
    );
  }

  Future<void> _requestReturn(BorrowModel item) async {
    final err = await _controller.requestReturn(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Return requested')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Borrowed Items'),
          actions: [
            IconButton(
              onPressed: _controller.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Held deposit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_controller.heldDeposit} Baht',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
            Expanded(
              child: _controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.error != null
                      ? Center(child: Text(_controller.error!))
                      : TabBarView(
                          children: [
                            _BorrowList(
                              items: _controller.borrowing,
                              onOpen: (item) => Navigator.pushNamed(
                                context,
                                '/borrow-details',
                                arguments: item.id,
                              ),
                              actionLabel: 'Request return',
                              onAction: (item) async {
                                if (item.status == 'borrowed') {
                                  await _requestReturn(item);
                                }
                              },
                            ),
                            _BorrowList(
                              items: _controller.pending,
                              onOpen: (item) => Navigator.pushNamed(
                                context,
                                '/borrow-details',
                                arguments: item.id,
                              ),
                              actionLabel: 'Cancel',
                              onAction: _cancel,
                            ),
                            _BorrowList(
                              items: _controller.returned,
                              onOpen: (item) => Navigator.pushNamed(
                                context,
                                '/borrow-details',
                                arguments: item.id,
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorrowList extends StatelessWidget {
  final List<BorrowModel> items;
  final void Function(BorrowModel item) onOpen;
  final String? actionLabel;
  final Future<void> Function(BorrowModel item)? onAction;

  const _BorrowList({
    required this.items,
    required this.onOpen,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items to display'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final returnDate = item.plannedReturnDate;
        final parsed = AppDateUtils.tryParseYmd(returnDate);
        return Card(
          child: ListTile(
            title: Text(item.assetName ?? 'Item #${item.assetId}'),
            subtitle: Text(
              'Status: ${item.status}\n'
              'Return: ${parsed == null ? (returnDate ?? '—') : AppDateUtils.formatDisplay(parsed)}\n'
              'Total: ${item.totalAmount ?? '—'} Baht',
            ),
            isThreeLine: true,
            onTap: () => onOpen(item),
            trailing: actionLabel != null && onAction != null
                ? TextButton(
                    onPressed: () => onAction!(item),
                    child: Text(actionLabel!),
                  )
                : const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

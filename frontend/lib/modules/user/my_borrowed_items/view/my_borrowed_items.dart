import 'package:flutter/material.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/my_borrowed_items/controller/my_borrowed_controller.dart';
import 'package:frontend/utils/date_utils.dart';
import 'package:frontend/widgets/user_app_bar.dart';

const _blue = Color(0xFF2F4BFF);
const _red = Color.fromARGB(255, 223, 42, 42);

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
      SnackBar(
        content: Text(
          err ?? 'Request cancelled. Your payment was refunded to your wallet',
        ),
      ),
    );
  }

  // กด Request return: ขึ้น popup ให้ยืนยันก่อนส่งคำขอคืน
  Future<void> _requestReturn(BorrowModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm return'),
        content: Text(
          'Do you want to request to return "${item.assetName ?? 'this item'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final err = await _controller.requestReturn(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? 'Return requested')));
  }

  void _openDetails(BorrowModel item) {
    Navigator.pushNamed(context, '/borrow-details', arguments: item.id);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: UserAppBar(
          title: 'My Borrowed Items',
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
                        // Borrowing: วันคืนอยู่ด้านขวาของกล่อง + ปุ่ม Request return สีน้ำเงิน
                        _BorrowList(
                          items: _controller.borrowing,
                          dateSide: _DateSide.right,
                          onOpen: _openDetails,
                          buttonBuilder: (item) => item.status == 'borrowed'
                              ? _ActionButton(
                                  label: 'Request return',
                                  color: _blue,
                                  onPressed: () => _requestReturn(item),
                                )
                              : Text(
                                  item.status == 'approved'
                                      ? 'Approved - open details to confirm receipt'
                                      : 'Waiting for owner to confirm return',
                                ),
                        ),
                        // Pending: วันคืนอยู่ด้านซ้ายของกล่อง + ปุ่ม Cancel สีแดง
                        _BorrowList(
                          items: _controller.pending,
                          dateSide: _DateSide.left,
                          onOpen: _openDetails,
                          buttonBuilder: (item) => _ActionButton(
                            label: 'Cancel',
                            color: _red,
                            onPressed: () => _cancel(item),
                          ),
                        ),
                        // Returned: วันคืนอยู่ด้านขวาของกล่อง
                        _BorrowList(
                          items: _controller.returned,
                          dateSide: _DateSide.right,
                          onOpen: _openDetails,
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

enum _DateSide { left, right }

class _BorrowList extends StatelessWidget {
  final List<BorrowModel> items;
  final _DateSide dateSide;
  final void Function(BorrowModel item) onOpen;
  final Widget Function(BorrowModel item)? buttonBuilder;

  const _BorrowList({
    required this.items,
    required this.dateSide,
    required this.onOpen,
    this.buttonBuilder,
  });

  // กล่องแสดงวันที่ต้องคืน (หัวข้อเล็ก + วันที่ตัวหนา)
  Widget _dateBox(BorrowModel item) {
    final raw = item.plannedReturnDate;
    final parsed = AppDateUtils.tryParseYmd(raw);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Return by', style: TextStyle(fontSize: 11)),
        Text(
          parsed == null ? (raw ?? '—') : AppDateUtils.formatDisplay(parsed),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

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
        final button = buttonBuilder?.call(item);
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: dateSide == _DateSide.left ? _dateBox(item) : null,
                title: Text(item.assetName ?? 'Item #${item.assetId}'),
                subtitle: Text(
                  'Status: ${item.status}\n'
                  'Total: ${item.totalAmount ?? '—'} Baht',
                ),
                isThreeLine: true,
                trailing: dateSide == _DateSide.right ? _dateBox(item) : null,
                onTap: () => onOpen(item),
              ),
              if (button != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 8),
                    child: button,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ปุ่มพื้นสีทึบ ข้อความสีขาว
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

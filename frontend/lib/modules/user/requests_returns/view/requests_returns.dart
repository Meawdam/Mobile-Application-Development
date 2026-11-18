import 'package:flutter/material.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/requests_returns/controller/requests_returns_controller.dart';
import 'package:frontend/utils/date_utils.dart';
import 'package:frontend/widgets/user_app_bar.dart';

const _blue = Color(0xFF2F4BFF);
const _red = Color.fromARGB(255, 223, 42, 42);

class RequestsReturnsScreen extends StatefulWidget {
  const RequestsReturnsScreen({super.key});

  @override
  State<RequestsReturnsScreen> createState() => _RequestsReturnsScreenState();
}

class _RequestsReturnsScreenState extends State<RequestsReturnsScreen> {
  final _controller = RequestsReturnsController();

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

  void _showResult(String? err, String successMessage) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? successMessage)));
  }

  Future<void> _approve(BorrowModel item) async {
    final err = await _controller.approve(item.id);
    _showResult(err, 'Request approved');
  }

  // กด Reject: ขึ้น popup ให้กรอกเหตุผล (backend บังคับต้องมีเหตุผล)
  Future<void> _reject(BorrowModel item) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: reasonController,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    // reasonController.dispose();
    if (reason == null) return;

    final err = await _controller.reject(item.id, reason);
    _showResult(err, 'Request rejected');
  }

  Future<void> _confirmReturn(BorrowModel item) async {
    final err = await _controller.confirmReturn(item.id);
    _showResult(err, 'Return confirmed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserAppBar(
        title: 'Requests & Returns',
        actions: [
          IconButton(
            onPressed: _controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _controller.loading
          ? const Center(child: CircularProgressIndicator())
          : _controller.error != null
          ? Center(child: Text(_controller.error!))
          : RefreshIndicator(
              onRefresh: _controller.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Waiting for Response',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  // คำขอที่รอตอบ: ปุ่ม Approve (น้ำเงิน) และ Reject (แดง)
                  // ผู้ยืมกดยกเลิกแล้ว: ข้อความ Cancel สีแดงด้านขวา
                  _BorrowSection(
                    items: _controller.waitingForResponse,
                    trailingBuilder: (item) => item.status == 'cancelled'
                        ? const Text(
                            'Cancel',
                            style: TextStyle(
                              color: _red,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    actionsBuilder: (item) => item.status == 'requested'
                        ? [
                            _ActionButton(
                              label: 'Approve',
                              color: _blue,
                              onPressed: () => _approve(item),
                            ),
                            _ActionButton(
                              label: 'Reject',
                              color: _red,
                              onPressed: () => _reject(item),
                            ),
                          ]
                        : const [],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Borrowed Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  // ปุ่ม Confirm (น้ำเงิน) แสดงเมื่อผู้ยืมแจ้งคืนแล้ว
                  _BorrowSection(
                    items: _controller.borrowedItems,
                    actionsBuilder: (item) => item.status == 'returned_pending'
                        ? [
                            _ActionButton(
                              label: 'Confirm',
                              color: _blue,
                              onPressed: () => _confirmReturn(item),
                            ),
                          ]
                        : const [],
                  ),
                ],
              ),
            ),
    );
  }
}

class _BorrowSection extends StatelessWidget {
  final List<BorrowModel> items;
  final Widget? Function(BorrowModel item)? trailingBuilder;
  final List<Widget> Function(BorrowModel item)? actionsBuilder;

  const _BorrowSection({
    required this.items,
    this.trailingBuilder,
    this.actionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No items to display')),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final parsed = AppDateUtils.tryParseYmd(item.plannedReturnDate);
        final actions = actionsBuilder?.call(item) ?? const <Widget>[];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(item.assetName ?? 'Item #${item.assetId}'),
                  subtitle: Text(
                    'Borrower: ${item.borrowerName ?? '—'}\n'
                    'Status: ${item.status}\n'
                    'Return: ${parsed == null ? (item.plannedReturnDate ?? '—') : AppDateUtils.formatDisplay(parsed)}',
                  ),
                  isThreeLine: true,
                  trailing: trailingBuilder?.call(item),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/borrow-details',
                    arguments: item.id,
                  ),
                ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 8,
                      children: actions,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
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

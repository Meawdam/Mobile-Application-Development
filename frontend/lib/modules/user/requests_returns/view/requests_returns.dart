import 'package:flutter/material.dart';

import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/modules/user/requests_returns/controller/requests_returns_controller.dart';
import 'package:frontend/utils/date_utils.dart';

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

  Future<void> _confirmReturn(BorrowModel item) async {
    final err = await _controller.confirmReturn(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Return confirmed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests & Returns'),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BorrowSection(
                        items: _controller.waitingForResponse,
                        emptyLabel: 'No items to display',
                        actionBuilder: (item) {
                          if (item.status != 'returned_pending') {
                            return null;
                          }
                          return TextButton(
                            onPressed: () => _confirmReturn(item),
                            child: const Text('Confirm return'),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Borrowed Items',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BorrowSection(
                        items: _controller.borrowedItems,
                        emptyLabel: 'No items to display',
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _BorrowSection extends StatelessWidget {
  final List<BorrowModel> items;
  final String emptyLabel;
  final Widget? Function(BorrowModel item)? actionBuilder;

  const _BorrowSection({
    required this.items,
    required this.emptyLabel,
    this.actionBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(emptyLabel)),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final parsed = AppDateUtils.tryParseYmd(item.plannedReturnDate);
        final action = actionBuilder?.call(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              title: Text(item.assetName ?? 'Item #${item.assetId}'),
              subtitle: Text(
                'Borrower: ${item.borrowerName ?? '—'}\n'
                'Status: ${item.status}\n'
                'Return: ${parsed == null ? (item.plannedReturnDate ?? '—') : AppDateUtils.formatDisplay(parsed)}',
              ),
              isThreeLine: true,
              trailing: action,
              onTap: () => Navigator.pushNamed(
                context,
                '/borrow-details',
                arguments: item.id,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

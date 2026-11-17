import 'package:flutter/material.dart';

import '../../payment/controller/payment_controller.dart';
import '../../payment/model/payment_model.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final PaymentController _controller = PaymentController();
  List<PaymentTransaction> allTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _refundingTransactionId;

  static const Color _blue = Color(0xFF2F4BFF);
  static const Color _green = Color.fromARGB(255, 72, 230, 83);
  static const Color _red = Color.fromARGB(255, 223, 42, 42);
  static const Color _onLight = Color(0xFF172554);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final transactions = await _controller.fetchTransactions(limit: 100);
      if (!mounted) return;
      setState(() => allTransactions = transactions);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refund(PaymentTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: Text('Return the held deposit to ${transaction.user}? You can do this after the item is confirmed returned and the deposit refund is pending.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _refundingTransactionId = transaction.id);
    final success = await _controller.refundTransaction(transaction);
    if (!mounted) return;
    if (!success) {
      setState(() => _refundingTransactionId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage ?? 'Refund failed.')),
      );
      return;
    }

    await _loadTransactions();
    if (!mounted) return;
    setState(() => _refundingTransactionId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refund processed successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _controller
        .filterTransactions(allTransactions, selectedFilter)
        .where((transaction) {
          final query = _searchController.text.toLowerCase();
          return query.isEmpty ||
              transaction.title.toLowerCase().contains(query) ||
              transaction.user.toLowerCase().contains(query) ||
              transaction.time.toLowerCase().contains(query);
        })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('All Transactions History'),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh records',
            onPressed: _isLoading ? null : _loadTransactions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, item or date...',
                prefixIcon: const Icon(Icons.search, color: _blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _blue, width: 1.5),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterTab('All'),
                const SizedBox(width: 8),
                _buildFilterTab('Pending Refund'),
                const SizedBox(width: 8),
                _buildFilterTab('Collected'),
                const SizedBox(width: 8),
                _buildFilterTab('Refunded'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _loadTransactions,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                : filteredList.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final tx = filteredList[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tx.isIncome
                                  ? _green.withOpacity(0.15)
                                  : _red.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tx.isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: tx.isIncome ? _green : _red,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            tx.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _onLight,
                            ),
                          ),
                          subtitle: Text(
                            'Name : ${tx.user} | ${tx.time}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          trailing: tx.isRefundable
                              ? ElevatedButton(
                                  onPressed: _refundingTransactionId == tx.id
                                      ? null
                                      : () => _refund(tx),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: const Size(0, 30),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _refundingTransactionId == tx.id
                                        ? 'Processing...'
                                        : 'Refund',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Text(
                                  tx.amount,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: tx.isIncome ? _green : _red,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String category) {
    bool isSelected = selectedFilter == category;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _blue : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

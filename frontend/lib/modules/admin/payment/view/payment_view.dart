import 'package:flutter/material.dart';
import 'package:frontend/modules/admin/all_transactions/view/all_transactions_view.dart';

import '../controller/payment_controller.dart';
import '../model/payment_model.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/model/dashboard_model.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _blue = Color(0xFF2F4BFF);
  static const _red = Color.fromARGB(255, 223, 42, 42);
  static const _green = Color.fromARGB(255, 72, 230, 83);
  static const _onLight = Color(0xFF172554);

  final PaymentController _paymentController = PaymentController();
  final DashboardController _dashboardController = DashboardController();
  List<PaymentTransaction> _transactions = [];
  DashboardStats? _stats;
  bool _isLoading = true;
  bool _isRefunding = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await _paymentController.fetchTransactions(limit: 4);
      if (mounted) setState(() => _transactions = transactions);
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _errorMessage = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }

    try {
      final stats = await _dashboardController.fetchDashboardStats();
      if (mounted) setState(() => _stats = stats);
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage ??= error.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refund(PaymentTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: Text(
          'Return the held deposit to ${transaction.user}? You can do this after the item is confirmed returned and the deposit refund is pending.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isRefunding = true);
    final success = await _paymentController.refundTransaction(transaction);
    if (!mounted) return;
    if (!success) {
      setState(() => _isRefunding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_paymentController.errorMessage ?? 'Refund failed.'),
        ),
      );
      return;
    }

    await _load();
    if (!mounted) return;
    setState(() => _isRefunding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refund processed successfully!'),
        backgroundColor: _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment & Refund Management',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: _onLight,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track collected revenues, held deposits, and process refunds',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _buildStatCard(
                'Collected Revenue',
                _stats == null
                    ? '--'
                    : _formatCurrency(_stats!.collectedRevenue),
                _green,
              ),
              _buildStatCard(
                'Held Deposits',
                _stats == null ? '--' : _formatCurrency(_stats!.heldDeposits),
                _blue,
              ),
              _buildStatCard(
                'Pending Refunds',
                _stats?.pendingRefunds.toString() ?? '--',
                _red,
              ),
              _buildStatCard(
                'Processed Refunds',
                _stats == null
                    ? '--'
                    : _formatCurrency(_stats!.processedRefunds),
                _blue,
              ),
            ],
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: _red),
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Payment Logs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _onLight,
                ),
              ),
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllTransactionsScreen(),
                    ),
                  );
                  if (mounted) _load();
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    color: _blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_transactions.isEmpty && !_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No transactions found')),
            )
          else
            for (final transaction in _transactions) ...[
              _buildTransactionCard(transaction),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '฿$whole.${parts.last}';
  }

  Widget _buildStatCard(String title, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: transaction.isIncome
                        ? _green.withOpacity(0.15)
                        : _red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transaction.isIncome
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.isIncome ? _green : _red,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${transaction.user} | ${transaction.time}',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          if (transaction.isRefundable)
            ElevatedButton(
              onPressed: _isRefunding ? null : () => _refund(transaction),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Refund',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else
            Text(
              transaction.amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: transaction.isIncome ? _green : _red,
              ),
            ),
        ],
      ),
    );
  }
}

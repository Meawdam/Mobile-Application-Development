import 'package:flutter/material.dart';

import '../../all_transactions/view/all_transactions_view.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // ðŸ”¹ à¸à¸£à¸­à¸šà¸à¸²à¸£à¹Œà¸”à¹ƒà¸«à¸à¹ˆà¸„à¸£à¸­à¸šà¸„à¸¥à¸¸à¸¡à¸—à¸¸à¸à¸ªà¹ˆà¸§à¸™à¸‚à¸­à¸‡à¸à¸²à¸£à¸ˆà¸±à¸”à¸à¸²à¸£à¹€à¸‡à¸´à¸™à¹ƒà¸«à¹‰à¸­à¸¢à¸¹à¹ˆà¹ƒà¸™à¸à¸£à¸­à¸šà¹€à¸”à¸µà¸¢à¸§à¸à¸±à¸™
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ðŸ”¹ à¸«à¸±à¸§à¸‚à¹‰à¸­à¸«à¸¥à¸±à¸à¹à¸¥à¸°à¸„à¸³à¸­à¸˜à¸´à¸šà¸²à¸¢à¸¢à¹ˆà¸­à¸¢à¸ à¸²à¸¢à¹ƒà¸™à¸à¸£à¸­à¸šà¹€à¸”à¸µà¸¢à¸§à¸à¸±à¸™
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Payment & Refund Management',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF0000A0),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Track collected revenues, held deposits, and process refunds',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),

          // à¸à¸²à¸£à¹Œà¸”à¸ªà¸£à¸¸à¸›à¸¢à¸­à¸”à¸à¸²à¸£à¹€à¸‡à¸´à¸™ (Stats Grid)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.9,
            children: [
              _buildStatCard('Collected Revenue', 'à¸¿12,350', Colors.green),
              _buildStatCard('Held Deposits', 'à¸¿84,500', Colors.indigo),
              _buildStatCard('Pending Fines', 'à¸¿450', Colors.orange),
              _buildStatCard('Processed Refunds', 'à¸¿3,200', Colors.blue),
            ],
          ),
          const SizedBox(height: 20),

          // à¸«à¸±à¸§à¸‚à¹‰à¸­à¸¢à¹ˆà¸­à¸¢à¸£à¸²à¸¢à¸à¸²à¸£à¸˜à¸¸à¸£à¸à¸£à¸£à¸¡à¸¥à¹ˆà¸²à¸ªà¸¸à¸” à¸žà¸£à¹‰à¸­à¸¡à¸›à¸¸à¹ˆà¸¡ View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Payment Logs',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllTransactionsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // à¸£à¸²à¸¢à¸à¸²à¸£à¸˜à¸¸à¸£à¸à¸£à¸£à¸¡à¸¢à¹ˆà¸­à¸¢à¹† à¸ à¸²à¸¢à¹ƒà¸™à¸à¸£à¸­à¸šà¹€à¸”à¸µà¸¢à¸§à¸à¸±à¸™
          _buildTransactionItem(
            context: context,
            title: 'Deposit Held - Lab Coat',
            subtitle: 'Somchai Jaidee | Today 10:15',
            amount: '+à¸¿500.00',
            isIncome: true,
            showRefundButton: true,
          ),
          const Divider(height: 16, color: Color(0xFFF3F4F6)),

          _buildTransactionItem(
            context: context,
            title: 'Fine Payment - Overdue',
            subtitle: 'Thanakon Srisuk | Yesterday',
            amount: '+à¸¿50.00',
            isIncome: true,
            showRefundButton: false,
          ),
          const Divider(height: 16, color: Color(0xFFF3F4F6)),

          _buildTransactionItem(
            context: context,
            title: 'Deposit Refunded',
            subtitle: 'Anucha Khetthong | Refunded Oct 28',
            amount: '-à¸¿500.00',
            isIncome: false,
            showRefundButton: false,
          ),
          const Divider(height: 16, color: Color(0xFFF3F4F6)),

          _buildTransactionItem(
            context: context,
            title: 'Deposit Held - Microscope',
            subtitle: 'Pimchanok Sriboon | Oct 27',
            amount: '+à¸¿1,500.00',
            isIncome: true,
            showRefundButton: true,
          ),
        ],
      ),
    );
  }

  // Widget à¸à¸²à¸£à¹Œà¸”à¹à¸ªà¸”à¸‡à¸œà¸¥à¸ªà¸–à¸´à¸•à¸´à¸¢à¹ˆà¸­à¸¢
  Widget _buildStatCard(String title, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Widget à¹à¸ªà¸”à¸‡à¸£à¸²à¸¢à¸à¸²à¸£à¸˜à¸¸à¸£à¸à¸£à¸£à¸¡
  Widget _buildTransactionItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String amount,
    required bool isIncome,
    required bool showRefundButton,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isIncome
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 10,
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

        if (showRefundButton)
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text(
                      'Confirm Refund',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to process the refund for "$title"?',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refund processed successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm Refund'),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 30),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Refund',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        else
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
      ],
    );
  }
}

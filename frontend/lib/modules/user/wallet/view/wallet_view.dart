import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/modules/user/wallet/controller/wallet_controller.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _walletController = WalletController();

  Future<void> _topUp() async {
    var amountText = '';
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Top up wallet'),
        content: TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => amountText = value,
          decoration: const InputDecoration(
            labelText: 'Amount (฿)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final enteredAmount = int.tryParse(amountText);
              if (enteredAmount == null || enteredAmount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter an amount greater than 0'),
                  ),
                );
                return;
              }

              Navigator.of(dialogContext).pop(enteredAmount);
            },
            child: const Text('Top up'),
          ),
        ],
      ),
    );

    if (amount == null || !mounted) {
      return;
    }

    if (_walletController.topUp(amount)) {
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Added ฿$amount to wallet')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2F4BFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Wallet balance',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '฿${_walletController.balance}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _topUp,
                child: const Text('Top up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

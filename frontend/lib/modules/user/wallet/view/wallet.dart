import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/modules/user/wallet/controller/wallet_controller.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _controller = WalletController();
  final _amountController = TextEditingController();

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
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _topUp() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final ok = await _controller.topUp(amount);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            amount <= 0
                ? 'Enter a positive amount'
                : (_controller.error ?? 'Top up failed'),
          ),
        ),
      );
      return;
    }

    _amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet topped up')),
    );
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
                    _controller.loading
                        ? '...'
                        : '${_controller.balance} Baht',
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
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Top-up amount (Baht)',
                hintText: 'e.g. 1000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _controller.submitting ? null : _topUp,
                child: Text(
                  _controller.submitting ? 'Processing...' : 'Top up',
                ),
              ),
            ),
            if (_controller.error != null && !_controller.submitting) ...[
              const SizedBox(height: 12),
              Text(
                _controller.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

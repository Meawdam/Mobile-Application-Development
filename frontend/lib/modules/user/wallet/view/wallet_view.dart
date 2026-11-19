import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/modules/user/wallet/controller/wallet_controller.dart';
import 'package:frontend/widgets/user_app_bar.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.controller});

  final WalletController? controller;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final _controller = widget.controller ?? WalletController();
  final _amountController = TextEditingController();
  String? _amountError;

  static const _quickAmounts = [100, 500, 1000, 5000];

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
    if (widget.controller == null) _controller.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _selectAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
      _amountError = null;
    });
  }

  Future<void> _topUp() async {
    final amount = num.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter an amount greater than zero.');
      return;
    }

    setState(() => _amountError = null);
    final success = await _controller.topUpOnline(amount);
    if (!mounted) return;
    if (success) {
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your wallet has been topped up.')),
      );
    } else {
      setState(() {
        _amountError = _controller.error ?? 'Top up failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: UserAppBar(
        title: 'My wallet',
        actions: [
          IconButton(
            tooltip: 'Refresh balance',
            onPressed: _controller.loading ? null : _controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _BalanceCard(
              balance: _controller.balance,
              loading: _controller.loading,
              error: _controller.loadError,
              onRetry: _controller.load,
            ),
            const SizedBox(height: 28),
            Text(
              'Add money',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF17233C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose an amount or enter your own.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts.map((amount) {
                final selected = _amountController.text == amount.toString();
                return ChoiceChip(
                  label: Text('฿${amount.toString()}'),
                  selected: selected,
                  onSelected: (_) => _selectAmount(amount),
                  selectedColor: const Color(0xFFE2E9FF),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF3156D8)
                        : const Color(0xFF344054),
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF3156D8)
                        : const Color(0xFFE4E8F0),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) {
                if (_amountError != null) {
                  setState(() => _amountError = null);
                } else {
                  setState(() {});
                }
              },
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixText: '฿  ',
                helperText: 'Maximum top-up: ฿1,000,000',
                errorText: _amountError ?? _controller.error,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _controller.submitting ? null : _topUp,
                icon: _controller.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  _controller.submitting ? 'Adding money...' : 'Add to wallet',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3156D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _WalletNote(),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final num balance;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263B91), Color(0xFF4169E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3156D8).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Text(
                'BORROW WALLET',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Available balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (loading)
            const SizedBox(
              height: 42,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (error != null)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Balance unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          else
            Text(
              '฿${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Use your balance for borrowing payments.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WalletNote extends StatelessWidget {
  const _WalletNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF3156D8), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Top-ups are securely applied to your account balance.',
              style: TextStyle(
                color: Color(0xFF344054),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../controller/dashboard_controller.dart';
import '../model/dashboard_model.dart';
import 'package:frontend/utils/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToApprove;
  final VoidCallback? onNavigateToRecords;
  final DashboardController? controller;

  const AdminDashboardScreen({super.key, this.onNavigateToApprove, this.onNavigateToRecords, this.controller});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _blue = AppColors.blue;
  static const _navy = Color(0xFF172554);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE5EAF2);

  late final DashboardController _controller;
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DashboardController();
    _statsFuture = _controller.fetchDashboardStats();
  }

  Future<void> _reload() async {
    setState(() => _statsFuture = _controller.fetchDashboardStats());
    try {
      await _statsFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateLabel = '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return Container(
      color: const Color(0xFFF5F7FC),
      child: FutureBuilder<DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final stats = snapshot.data;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Good day, Admin', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: _navy)),
                                  const SizedBox(height: 5),
                                  Text('$dateLabel  ·  Here’s what’s happening today.', style: const TextStyle(color: _muted, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Refresh dashboard',
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh_rounded),
                              style: IconButton.styleFrom(foregroundColor: _blue, backgroundColor: const Color(0xFFE8ECFF)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (snapshot.connectionState == ConnectionState.waiting) ...[
                          const SizedBox(height: 14),
                          const LinearProgressIndicator(minHeight: 3),
                        ],
                        if (snapshot.hasError) ...[
                          const SizedBox(height: 14),
                          _errorPanel(snapshot.error.toString().replaceFirst('Exception: ', '')),
                        ],
                        const SizedBox(height: 22),
                        const Text('Platform overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: constraints.maxWidth < 500 ? 1.1 : 1.75,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _metricCard('Approved items', stats?.approvedCount.toString() ?? '—', Icons.inventory_2_outlined, const Color(0xFF16845B), const Color(0xFFE8F7F0)),
                                _metricCard('Waiting for review', stats?.pendingCount.toString() ?? '—', Icons.pending_actions_rounded, const Color(0xFFB7791F), const Color(0xFFFFF6DF), onTap: widget.onNavigateToApprove),
                                _metricCard('Currently borrowed', stats?.borrowedCount.toString() ?? '—', Icons.swap_horiz_rounded, _blue, const Color(0xFFE8ECFF)),
                                _metricCard('Deposits held', stats == null ? '—' : _currency(stats.heldDeposits), Icons.account_balance_wallet_outlined, const Color(0xFFB54747), const Color(0xFFFFEEEE)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final chart = _borrowingCard(stats);
                            final finances = _financeCard(stats, widget.onNavigateToRecords);
                            if (constraints.maxWidth < 760) {
                              return Column(children: [chart, const SizedBox(height: 12), finances]);
                            }
                            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: chart), const SizedBox(width: 12), Expanded(flex: 2, child: finances)]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color accent, Color tint, {VoidCallback? onTap}) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: accent, size: 19)), const Spacer(), if (onTap != null) Icon(Icons.arrow_outward_rounded, size: 16, color: accent)]),
          const Spacer(),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _navy)),
          const SizedBox(height: 3),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.1, color: _muted, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );

  Widget _borrowingCard(DashboardStats? stats) => _panel(
    title: 'Borrowing activity',
    subtitle: 'Daily requests over the last 7 days',
    child: stats == null || stats.borrowingVolume.isEmpty
        ? const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: Text('No borrowing activity yet', style: TextStyle(color: _muted))))
        : SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround, children: stats.borrowingVolume.map((day) {
            final maxCount = stats.borrowingVolume.fold<int>(0, (max, entry) => entry.count > max ? entry.count : max);
            final date = DateTime.tryParse(day.date);
            final label = date == null ? day.date : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
            final barHeight = maxCount == 0 ? 4.0 : (86 * day.count / maxCount).clamp(4.0, 86.0).toDouble();
            return Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text('${day.count}', style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Container(width: 22, height: barHeight, decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8))), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 10, color: _muted))]);
          }).toList())),
  );

  Widget _financeCard(DashboardStats? stats, VoidCallback? onViewRefunds) => _panel(
    title: 'Finance snapshot',
    subtitle: 'Deposits and refunds',
    child: Column(children: [
      _financeRow(Icons.payments_outlined, 'Collected revenue', stats == null ? '—' : _currency(stats.collectedRevenue), const Color(0xFF16845B)),
      const Divider(height: 22),
      _financeRow(Icons.hourglass_bottom_rounded, 'Refunds to process', stats?.pendingRefunds.toString() ?? '—', const Color(0xFFB7791F)),
      if ((stats?.pendingRefunds ?? 0) > 0 && onViewRefunds != null)
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onViewRefunds, icon: const Icon(Icons.arrow_forward_rounded, size: 16), label: const Text('Review refunds'))),
      const Divider(height: 22),
      _financeRow(Icons.check_circle_outline, 'Refunds completed', stats == null ? '—' : _currency(stats.processedRefunds), _blue),
    ]),
  );

  Widget _financeRow(IconData icon, String label, String value, Color color) => Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600))), Text(value, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 13))]);

  Widget _panel({required String title, required String subtitle, required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)), const SizedBox(height: 18), child]),
  );

  Widget _errorPanel(String message) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [const Icon(Icons.error_outline, color: Color(0xFFB54747)), const SizedBox(width: 8), Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF9B2C2C)))), TextButton(onPressed: _reload, child: const Text('Retry'))]),
  );

  String _currency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '฿$whole.${parts.last}';
  }
}

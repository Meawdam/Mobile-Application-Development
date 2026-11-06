import 'package:flutter/material.dart';

import '../../../models/borrow_models.dart';
import '../../../utils/date_format_th.dart';
import '../../../utils/responsive.dart';
import '../../borrow_details/borrow_details_module.dart';
import '../../borrow_request/borrow_request_module.dart';

const _bg = Color(0xFFF5F7FB);
const _navy = Color(0xFF1A2138);
const _primary = Color(0xFF3B54F6);
const _muted = Color(0xFF8B93A7);

class MyBorrowedItemsPage extends StatefulWidget {
  const MyBorrowedItemsPage({
    super.key,
    this.highlightNewPayment = false,
    this.initialTab = 0,
  });

  final bool highlightNewPayment;
  final int initialTab;

  @override
  State<MyBorrowedItemsPage> createState() => _MyBorrowedItemsPageState();
}

class _MyBorrowedItemsPageState extends State<MyBorrowedItemsPage> {
  late int _tab;
  late List<BorrowRecord> _records;

  static final DateTime _demoNow = DateTime(2026, 10, 30);

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _records = List.of(AppBorrowData.records);
    if (widget.highlightNewPayment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ชำระเงินสำเร็จ (จำลอง) — รายการอยู่ในแท็บ Pending'),
          ),
        );
      });
    }
  }

  List<BorrowRecord> get _filtered {
    switch (_tab) {
      case 0:
        return _records
            .where((e) =>
                e.status == BorrowListStatus.borrowing ||
                e.status == BorrowListStatus.overdue)
            .toList();
      case 1:
        return _records
            .where((e) => e.status == BorrowListStatus.pending)
            .toList();
      default:
        return _records
            .where((e) => e.status == BorrowListStatus.returned)
            .toList();
    }
  }

  int get _borrowingCount => _records
      .where((e) =>
          e.status == BorrowListStatus.borrowing ||
          e.status == BorrowListStatus.overdue)
      .length;

  int get _pendingCount =>
      _records.where((e) => e.status == BorrowListStatus.pending).length;

  int get _heldDeposit => AppBorrowData.heldDepositTotal(_records);

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final items = _filtered;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: r.constrain(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(r.pagePadding + 4, 16, r.pagePadding, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        'My Borrowed Items',
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: r.isCompact ? 20 : 24,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BorrowRequestPage(),
                          ),
                        );
                      },
                      child: const AppText(
                        'ขอยืมของ',
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding + 4,
                  4,
                  r.pagePadding,
                  12,
                ),
                child: AppText(
                  'Held Deposit: ฿$_heldDeposit',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 14, color: _muted),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
                child: Row(
                  children: [
                    _SegChip(
                      label: 'Borrowing $_borrowingCount',
                      selected: _tab == 0,
                      compact: r.isCompact,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    const SizedBox(width: 8),
                    _SegChip(
                      label: 'Pending $_pendingCount',
                      selected: _tab == 1,
                      compact: r.isCompact,
                      onTap: () => setState(() => _tab = 1),
                    ),
                    const SizedBox(width: 8),
                    _SegChip(
                      label: 'Returned',
                      selected: _tab == 2,
                      compact: r.isCompact,
                      onTap: () => setState(() => _tab = 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: AppText(
                          'No items in this tab',
                          style: TextStyle(color: _muted),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          r.pagePadding,
                          4,
                          r.pagePadding,
                          16,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _BorrowCard(
                            record: item,
                            now: _demoNow,
                            compact: r.isCompact,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BorrowDetailsPage(record: item),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _BorrowBottomNav(activeIndex: 1),
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 36 : 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _navy : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? _navy : const Color(0xFFD5DAE6),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BorrowCard extends StatelessWidget {
  const _BorrowCard({
    required this.record,
    required this.now,
    required this.onTap,
    required this.compact,
  });

  final BorrowRecord record;
  final DateTime now;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badge = _badgeFor(record.status);
    final remaining = remainingTimeLabel(record.returnDate, now: now);
    final box = compact ? 46.0 : 52.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF2)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: box,
                      height: box,
                      decoration: BoxDecoration(
                        color: Color(record.imageTint ?? 0xFFD6E4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF7B8DB5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            record.name,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            'From ${record.ownerName}',
                            maxLines: 1,
                            style: const TextStyle(fontSize: 13, color: _muted),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badge.$1,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: AppText(
                              badge.$2,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: badge.$3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFB0B6C6),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8ECF4)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        formatEnRange(record.pickupDate, record.returnDate),
                        maxLines: 1,
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AppText(
                        remaining,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: record.status == BorrowListStatus.overdue
                              ? const Color(0xFFC0392B)
                              : _navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String, Color) _badgeFor(BorrowListStatus status) {
    switch (status) {
      case BorrowListStatus.borrowing:
        return (
          const Color(0xFFE4E9FF),
          'Borrowing',
          const Color(0xFF3B54F6),
        );
      case BorrowListStatus.overdue:
        return (
          const Color(0xFFFFE3E3),
          'Overdue 1 Day',
          const Color(0xFFC0392B),
        );
      case BorrowListStatus.pending:
        return (
          const Color(0xFFFFF0D6),
          'Waiting for lender',
          const Color(0xFFB86E00),
        );
      case BorrowListStatus.returned:
        return (
          const Color(0xFFE6F6EC),
          'Returned',
          const Color(0xFF1B7A45),
        );
    }
  }
}

class _BorrowBottomNav extends StatelessWidget {
  const _BorrowBottomNav({required this.activeIndex});
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EAF2))),
      ),
      padding: EdgeInsets.only(top: 8, bottom: 10 + bottom),
      child: Row(
        children: [
          _navItem(Icons.home_outlined, 'Home', 0),
          _navItem(Icons.menu_book_outlined, 'Borrowing', 1),
          _navItem(Icons.inventory_2_outlined, 'lending', 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = index == activeIndex;
    final color = active ? _primary : const Color(0xFF9AA1B5);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          AppText(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

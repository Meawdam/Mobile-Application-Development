import 'package:flutter/material.dart';

import 'models/borrow_models.dart';
import 'payment_page.dart';
import 'utils/date_format_th.dart';
import 'utils/responsive.dart';

const _bg = Color(0xFFF5F7FB);
const _primary = Color(0xFF3B54F6);
const _navy = Color(0xFF1A233A);
const _muted = Color(0xFF8B93A7);
const _cardBorder = Color(0xFFE6EAF2);

class BorrowRequestPage extends StatefulWidget {
  BorrowRequestPage({
    super.key,
    this.item = AppBorrowData.casio,
    DateTime? initialPickup,
    DateTime? initialReturn,
  })  : initialPickup = initialPickup ?? DateTime(2026, 11, 2),
        initialReturn = initialReturn ?? DateTime(2026, 11, 4);

  final BorrowCatalogItem item;
  final DateTime initialPickup;
  final DateTime initialReturn;

  @override
  State<BorrowRequestPage> createState() => _BorrowRequestPageState();
}

class _BorrowRequestPageState extends State<BorrowRequestPage> {
  late DateTime _pickup;
  late DateTime _return;
  late DateTime _visibleMonth;
  int _activeField = 0;

  @override
  void initState() {
    super.initState();
    _pickup = widget.initialPickup;
    _return = widget.initialReturn;
    _visibleMonth = DateTime(_pickup.year, _pickup.month);
  }

  int get _days => inclusiveDays(_pickup, _return);
  int get _priceTotal => widget.item.pricePerDay * _days;
  int get _grandTotal => _priceTotal + widget.item.deposit;

  void _onDayTapped(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    setState(() {
      if (_activeField == 0) {
        _pickup = d;
        final maxEnd = d.add(Duration(days: widget.item.maxDays - 1));
        if (_return.isBefore(d) || _return.isAfter(maxEnd)) {
          _return = d.isAfter(maxEnd) ? maxEnd : d;
          if (_return.isBefore(d)) _return = d;
          final preferred = d.add(const Duration(days: 2));
          _return = preferred.isAfter(maxEnd) ? maxEnd : preferred;
        }
        _activeField = 1;
      } else {
        final maxEnd = _pickup.add(Duration(days: widget.item.maxDays - 1));
        if (d.isBefore(_pickup)) {
          _pickup = d;
          _return = d;
        } else if (d.isAfter(maxEnd)) {
          _return = maxEnd;
        } else {
          _return = d;
        }
      }
    });
  }

  void _goPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          itemName: widget.item.name,
          ownerName: widget.item.ownerName,
          pickupDate: _pickup,
          returnDate: _return,
          priceTotal: _priceTotal,
          deposit: widget.item.deposit,
          days: _days,
          pricePerDay: widget.item.pricePerDay,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final stackDates = r.width < 340;

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: r.constrain(
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(r.pagePadding, 8, r.pagePadding, 8),
                child: Row(
                  children: [
                    _CircleBackButton(
                      size: r.iconBox(44),
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Expanded(
                      child: AppText(
                        'ขอยืมของ',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                    ),
                    SizedBox(width: r.iconBox(44)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    r.pagePadding,
                    4,
                    r.pagePadding,
                    r.pagePadding,
                  ),
                  children: [
                    _ItemSummaryCard(item: widget.item, compact: r.isCompact),
                    const SizedBox(height: 18),
                    const AppText(
                      'กำหนดวันรับและวันคืน',
                      maxLines: 2,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (stackDates) ...[
                      _DateBox(
                        label: 'วันรับของ',
                        value: formatThaiDayMonthYear(_pickup),
                        selected: _activeField == 0,
                        onTap: () => setState(() => _activeField = 0),
                      ),
                      const SizedBox(height: 10),
                      _DateBox(
                        label: 'วันคืนของ',
                        value: formatThaiDayMonthYear(_return),
                        selected: _activeField == 1,
                        onTap: () => setState(() => _activeField = 1),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: _DateBox(
                              label: 'วันรับของ',
                              value: formatThaiDayMonthYear(_pickup),
                              selected: _activeField == 0,
                              onTap: () => setState(() => _activeField = 0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateBox(
                              label: 'วันคืนของ',
                              value: formatThaiDayMonthYear(_return),
                              selected: _activeField == 1,
                              onTap: () => setState(() => _activeField = 1),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    _CalendarCard(
                      visibleMonth: _visibleMonth,
                      pickup: _pickup,
                      returnDate: _return,
                      compact: r.isCompact,
                      onPrev: () => setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month - 1,
                        );
                      }),
                      onNext: () => setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month + 1,
                        );
                      }),
                      onDayTap: _onDayTapped,
                    ),
                    const SizedBox(height: 12),
                    _PriceCard(
                      pricePerDay: widget.item.pricePerDay,
                      days: _days,
                      priceTotal: _priceTotal,
                      deposit: widget.item.deposit,
                      grandTotal: _grandTotal,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  8,
                  r.pagePadding,
                  16,
                ),
                child: AppBottomButton(
                  label: 'ไปหน้าชำระเงิน ฿$_grandTotal',
                  onPressed: _goPayment,
                  backgroundColor: _primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap, required this.size});
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _navy,
          ),
        ),
      ),
    );
  }
}

class _ItemSummaryCard extends StatelessWidget {
  const _ItemSummaryCard({required this.item, required this.compact});
  final BorrowCatalogItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final box = compact ? 48.0 : 56.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: const Color(0xFFD6E4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image_outlined, color: Color(0xFF7B8DB5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.name,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  'เจ้าของ ${item.ownerName} • ยืมได้สูงสุด ${item.maxDays} วัน',
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _primary : const Color(0xFFB8C4F5),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    label,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: _primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visibleMonth,
    required this.pickup,
    required this.returnDate,
    required this.compact,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  final DateTime visibleMonth;
  final DateTime pickup;
  final DateTime returnDate;
  final bool compact;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leading = first.weekday % 7;
    final daySize = compact ? 32.0 : 36.0;
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(visibleMonth.year, visibleMonth.month, day);
      cells.add(
        _DayCell(
          date: date,
          pickup: pickup,
          returnDate: returnDate,
          size: daySize,
          onTap: () => onDayTap(date),
        ),
      );
    }

    const headers = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 14, 12, compact ? 10 : 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded, color: _navy),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: AppText(
                  formatThaiMonthYear(visibleMonth),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _navy,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded, color: _navy),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: headers
                .map(
                  (h) => Expanded(
                    child: AppText(
                      h,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 2,
            childAspectRatio: compact ? 1 : 1.05,
            children: cells,
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              'เลือกวันรับ–วันคืนภายในระยะที่เจ้าของกำหนด (ไม่มีระบบจอง)',
              maxLines: 3,
              overflow: TextOverflow.clip,
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.pickup,
    required this.returnDate,
    required this.size,
    required this.onTap,
  });

  final DateTime date;
  final DateTime pickup;
  final DateTime returnDate;
  final double size;
  final VoidCallback onTap;

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isStart = _same(date, pickup);
    final isEnd = _same(date, returnDate);
    final inRange = !date.isBefore(pickup) && !date.isAfter(returnDate);
    final isEdge = isStart || isEnd;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Center(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEdge
                ? _primary
                : inRange
                    ? const Color(0xFFDCE3FF)
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: size < 34 ? 12 : 13,
              fontWeight: isEdge ? FontWeight.w700 : FontWeight.w500,
              color: isEdge ? Colors.white : _navy,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.pricePerDay,
    required this.days,
    required this.priceTotal,
    required this.deposit,
    required this.grandTotal,
  });

  final int pricePerDay;
  final int days;
  final int priceTotal;
  final int deposit;
  final int grandTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          _row('ราคา ฿$pricePerDay x $days วัน', '฿$priceTotal'),
          const SizedBox(height: 10),
          _row('เงินมัดจำ (คืนให้เมื่อคืนของ)', '฿$deposit'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE8ECF4)),
          ),
          Row(
            children: [
              const Expanded(
                child: AppText(
                  'ยอดที่ต้องชำระ',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppText(
                '฿$grandTotal',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String left, String right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppText(
            left,
            maxLines: 2,
            overflow: TextOverflow.clip,
            style: const TextStyle(fontSize: 13, color: _navy),
          ),
        ),
        const SizedBox(width: 8),
        AppText(
          right,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
      ],
    );
  }
}

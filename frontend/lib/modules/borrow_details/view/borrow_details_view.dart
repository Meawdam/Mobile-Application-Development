import 'package:flutter/material.dart';

import '../../../models/borrow_models.dart';
import '../../../utils/date_format_th.dart';
import '../../../utils/responsive.dart';

const _bg = Color(0xFFF5F5F5);
const _navy = Color(0xFF1A1F36);
const _primary = Color(0xFF3B59F5);
const _muted = Color(0xFF8B93A7);

class BorrowDetailsPage extends StatelessWidget {
  const BorrowDetailsPage({super.key, required this.record});

  final BorrowRecord record;

  static final DateTime _demoNow = DateTime(2026, 10, 30);

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final remaining = remainingTimeLabel(record.returnDate, now: _demoNow);
    final stackActions = r.width < 340;

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
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          width: r.iconBox(44),
                          height: r.iconBox(44),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: _navy,
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: AppText(
                        'Borrow Details',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
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
                    _ItemHeaderCard(record: record, compact: r.isCompact),
                    const SizedBox(height: 12),
                    _ReturnDeadlineCard(
                      record: record,
                      remaining: remaining,
                    ),
                    const SizedBox(height: 12),
                    _TransactionCard(
                      record: record,
                      compact: r.isCompact,
                    ),
                    const SizedBox(height: 12),
                    _TimelineCard(
                      currentStep: record.timelineStep,
                      compact: r.isCompact,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  12,
                  r.pagePadding,
                  16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE6EAF2))),
                ),
                child: stackActions
                    ? Column(
                        children: [
                          _reportButton(context),
                          const SizedBox(height: 10),
                          _declareButton(context),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _reportButton(context)),
                          const SizedBox(width: 10),
                          Expanded(child: _declareButton(context)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report Problem submitted (demo)')),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: _navy,
        side: const BorderSide(color: Color(0xFFD0D5E2)),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const AppText(
        'Report Problem',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _declareButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return declared — waiting for lender confirm'),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const AppText(
        'Declare Return',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _ItemHeaderCard extends StatelessWidget {
  const _ItemHeaderCard({required this.record, required this.compact});
  final BorrowRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final box = compact ? 48.0 : 56.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: Color(record.imageTint ?? 0xFFE4E9FF),
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
                  'Rental ID: ${record.id}',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4E9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppText(
                    _statusLabel(record.status),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B54F6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BorrowListStatus status) {
    switch (status) {
      case BorrowListStatus.borrowing:
        return 'Borrowed';
      case BorrowListStatus.overdue:
        return 'Overdue';
      case BorrowListStatus.pending:
        return 'Pending';
      case BorrowListStatus.returned:
        return 'Returned';
    }
  }
}

class _ReturnDeadlineCard extends StatelessWidget {
  const _ReturnDeadlineCard({
    required this.record,
    required this.remaining,
  });

  final BorrowRecord record;
  final String remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Return Date',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A6A3A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  '${formatEnDayMonthYear(record.returnDate)} • ${record.returnTimeLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  '$remaining • Overdue fine ฿${record.finePerDay}/day',
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A7A40),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF0C94A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _navy),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.record, required this.compact});
  final BorrowRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row(
            'Lender:',
            '${record.ownerName} • Tel ${record.ownerPhone}',
            compact,
          ),
          const Divider(height: 1, color: Color(0xFFE8ECF4)),
          _row(
            'Received Date:',
            '${formatEnShortDate(record.pickupDate)} • ${record.pickupLocation}',
            compact,
          ),
          const Divider(height: 1, color: Color(0xFFE8ECF4)),
          _row(
            'Price (${record.days} days):',
            '฿${record.priceTotal} • Paid',
            compact,
          ),
          const Divider(height: 1, color: Color(0xFFE8ECF4)),
          _row(
            'Deposit:',
            '฿${record.deposit} • Held in system',
            compact,
          ),
        ],
      ),
    );
  }

  Widget _row(String left, String right, bool compact) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              left,
              maxLines: 1,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 4),
            AppText(
              right,
              maxLines: 2,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 4,
            child: AppText(
              left,
              maxLines: 2,
              overflow: TextOverflow.clip,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: AppText(
              right,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.currentStep, required this.compact});
  final int currentStep;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const labels = ['Paid', 'Received', 'Borrowed', 'Returned'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Status timeline',
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final after = i ~/ 2;
                final done = after < currentStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: done
                        ? const Color(0xFF2EAE66)
                        : const Color(0xFFD5DAE6),
                  ),
                );
              }
              final step = i ~/ 2;
              return _StepDot(
                label: labels[step],
                compact: compact,
                state: step < currentStep
                    ? _StepState.done
                    : step == currentStep
                        ? _StepState.current
                        : _StepState.todo,
              );
            }),
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, current, todo }

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.state,
    required this.compact,
  });
  final String label;
  final _StepState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color fill;
    Widget child;
    switch (state) {
      case _StepState.done:
        fill = const Color(0xFF2EAE66);
        child = const Icon(Icons.check, size: 14, color: Colors.white);
      case _StepState.current:
        fill = const Color(0xFFF0C94A);
        child = const SizedBox.shrink();
      case _StepState.todo:
        fill = Colors.white;
        child = const SizedBox.shrink();
    }

    final size = compact ? 24.0 : 28.0;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: state == _StepState.todo
                ? Border.all(color: const Color(0xFFD5DAE6), width: 2)
                : null,
          ),
          child: Center(child: child),
        ),
        const SizedBox(height: 6),
        AppText(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: state == _StepState.todo ? _muted : _navy,
          ),
        ),
      ],
    );
  }
}

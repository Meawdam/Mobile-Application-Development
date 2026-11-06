import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/responsive.dart';
import '../../borrowed_items/borrowed_items_module.dart';

const _bg = Color(0xFFF5F7FB);
const _primary = Color(0xFF5C6FF5);
const _navy = Color(0xFF1A243D);
const _muted = Color(0xFF8B93A7);
const _disabledBtn = Color(0xFFD1D5E4);

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.itemName,
    required this.ownerName,
    required this.pickupDate,
    required this.returnDate,
    required this.priceTotal,
    required this.deposit,
    required this.days,
    required this.pricePerDay,
  });

  final String itemName;
  final String ownerName;
  final DateTime pickupDate;
  final DateTime returnDate;
  final int priceTotal;
  final int deposit;
  final int days;
  final int pricePerDay;

  int get total => priceTotal + deposit;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _controller = TextEditingController(text: '0');
  final _scrollController = ScrollController();
  final _amountFocus = FocusNode();
  int _amount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.45,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void _onChanged() {
    final raw = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(raw.isEmpty ? '0' : raw) ?? 0;
    if (value != _amount) {
      setState(() => _amount = value);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _scrollController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  bool get _canPay => _amount >= widget.total;

  void _payFull() {
    _controller.text = '${widget.total}';
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
  }

  void _confirmPay() {
    if (!_canPay) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MyBorrowedItemsPage(highlightNewPayment: true),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final amountSize = r.sp(r.isCompact ? 24 : 28, maxFactor: 1.15);
    final totalSize = r.sp(r.isCompact ? 30 : 36, maxFactor: 1.15);

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
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppText(
                        'ชำระเงิน',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: r.isCompact ? 20 : 22,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: r.scrollPadding.copyWith(
                    bottom: r.pagePadding + 8 + r.viewInsets.bottom,
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        r.isCompact ? 16 : 20,
                        18,
                        r.isCompact ? 16 : 20,
                        18,
                      ),
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'ยอดที่ต้องชำระ',
                            maxLines: 1,
                            style: TextStyle(
                              color: Color(0xFFB7BFD2),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppText(
                            '฿${widget.total}',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: totalSize,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            'ราคา ฿${widget.priceTotal}  มัดจำ ฿${widget.deposit}',
                            maxLines: 2,
                            style: const TextStyle(
                              color: Color(0xFFB7BFD2),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const AppText(
                      'ใส่จำนวนเงินที่ต้องการจ่าย',
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary, width: 2),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '฿',
                            style: TextStyle(
                              fontSize: amountSize,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB0B6C6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _amountFocus,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(
                                fontSize: amountSize,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: Color(0xFFB0B6C6),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _payFull,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE8EDFF),
                          foregroundColor: _primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: _primary.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        child: AppText(
                          'จ่ายเต็มจำนวน ฿${widget.total}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppText(
                      'ต้องชำระอย่างน้อย ฿${widget.total} · เงินมัดจำจะถูกพักไว้ในระบบและคืนให้เมื่อเจ้าของยืนยันว่าได้รับของคืนแล้ว',
                      maxLines: 5,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8D6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6C96A)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFC9A227),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: AppText(
                              'ระบบจำลองการชำระเงิน ไม่มีการตัดเงินจริง',
                              maxLines: 3,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4A4A4A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  label: _canPay
                      ? 'ยืนยันชำระเงิน ฿${widget.total}'
                      : 'ใส่จำนวนเงินให้ครบ ฿${widget.total}',
                  onPressed: _confirmPay,
                  disabled: !_canPay,
                  backgroundColor: _primary,
                  disabledBackgroundColor: _disabledBtn,
                  disabledForegroundColor: const Color(0xFF5C6478),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

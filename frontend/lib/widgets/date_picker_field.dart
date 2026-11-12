import 'package:flutter/material.dart';

import 'package:frontend/utils/date_utils.dart';

/// Outlined calendar field matching the lender/borrower date UI.
class DatePickerField extends StatelessWidget {
  final String label;
  final String hintText;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime>? onPicked;
  final bool enabled;
  final bool showCalendarIcon;

  const DatePickerField({
    super.key,
    required this.label,
    this.hintText = 'Select date',
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
    this.enabled = true,
    this.showCalendarIcon = false,
  });

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || onPicked == null) return;
    if (lastDate.isBefore(firstDate)) return;

    final initial = value == null
        ? firstDate
        : AppDateUtils.isWithinRange(
            value!,
            first: firstDate,
            last: lastDate,
          )
            ? value!
            : firstDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: label,
    );

    if (picked != null) {
      onPicked!(AppDateUtils.dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = value == null ? hintText : AppDateUtils.formatDisplay(value!);
    final hasValue = value != null;
    final borderColor = enabled
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).disabledColor;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: enabled,
        suffixIcon: showCalendarIcon
            ? IconButton(
                tooltip: 'Open calendar',
                onPressed: enabled ? () => _openPicker(context) : null,
                icon: const Icon(Icons.calendar_today_outlined),
              )
            : null,
      ),
      child: InkWell(
        onTap: enabled ? () => _openPicker(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            display,
            style: TextStyle(
              color: !enabled
                  ? Theme.of(context).disabledColor
                  : hasValue
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : borderColor,
            ),
          ),
        ),
      ),
    );
  }
}

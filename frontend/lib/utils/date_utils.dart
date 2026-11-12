/// Shared calendar/day helpers for lender and borrower date flows.
class AppDateUtils {
  const AppDateUtils._();

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime today() => dateOnly(DateTime.now());

  static DateTime? tryParseYmd(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = raw.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(normalized);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    return DateTime(year, month, day);
  }

  static String formatYmd(DateTime value) {
    final d = dateOnly(value);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  static String formatDisplay(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = dateOnly(value);
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Inclusive rental days: same-day pickup & return counts as 1 day.
  static int rentalDays(DateTime pickup, DateTime returnDate) {
    final start = dateOnly(pickup);
    final end = dateOnly(returnDate);
    final days = end.difference(start).inDays + 1;
    return days < 1 ? 1 : days;
  }

  static bool isWithinRange(
    DateTime value, {
    required DateTime first,
    required DateTime last,
  }) {
    final day = dateOnly(value);
    return !day.isBefore(dateOnly(first)) && !day.isAfter(dateOnly(last));
  }
}

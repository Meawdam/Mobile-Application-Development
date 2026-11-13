import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/date_utils.dart';

void main() {
  test('rentalDays is inclusive', () {
    expect(
      AppDateUtils.rentalDays(DateTime(2026, 11, 12), DateTime(2026, 11, 12)),
      1,
    );
    expect(
      AppDateUtils.rentalDays(DateTime(2026, 11, 12), DateTime(2026, 11, 14)),
      3,
    );
  });

  test('formatYmd and tryParseYmd round-trip', () {
    final date = DateTime(2026, 3, 5);
    expect(AppDateUtils.formatYmd(date), '2026-03-05');
    expect(AppDateUtils.tryParseYmd('2026-03-05T10:00:00Z'), DateTime(2026, 3, 5));
    expect(AppDateUtils.tryParseYmd(''), isNull);
  });

  test('isWithinRange includes first and last day', () {
    final first = DateTime(2026, 11, 1);
    final last = DateTime(2026, 11, 10);

    expect(
      AppDateUtils.isWithinRange(DateTime(2026, 11, 1), first: first, last: last),
      isTrue,
    );
    expect(
      AppDateUtils.isWithinRange(DateTime(2026, 11, 10), first: first, last: last),
      isTrue,
    );
    expect(
      AppDateUtils.isWithinRange(DateTime(2026, 11, 11), first: first, last: last),
      isFalse,
    );
  });
}

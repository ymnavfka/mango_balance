import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/features/statistics/domain/entities/period_type.dart';
import 'package:mango_balance/features/statistics/domain/usecases/compute_period_range.dart';

void main() {
  final ranges = ComputePeriodRange();

  test('month navigation does not skip shorter months in either direction', () {
    for (final year in [2023, 2024]) {
      final lastFebruaryDay = DateTime(year, 3, 0);
      expect(
        ranges.shiftAnchor(
          type: PeriodType.month,
          anchor: DateTime(year, 1, 31),
          direction: 1,
        ),
        lastFebruaryDay,
      );
      expect(
        ranges.shiftAnchor(
          type: PeriodType.month,
          anchor: DateTime(year, 3, 31),
          direction: -1,
        ),
        lastFebruaryDay,
      );
    }
  });

  test('month navigation crosses years and preserves valid days', () {
    expect(
      ranges.shiftAnchor(
        type: PeriodType.month,
        anchor: DateTime(2024, 12, 31),
        direction: 1,
      ),
      DateTime(2025, 1, 31),
    );
    expect(
      ranges.shiftAnchor(
        type: PeriodType.month,
        anchor: DateTime(2024, 1, 15),
        direction: -1,
      ),
      DateTime(2023, 12, 15),
    );
  });

  test('year navigation clamps leap day without moving into March', () {
    for (final direction in [-1, 1]) {
      expect(
        ranges.shiftAnchor(
          type: PeriodType.year,
          anchor: DateTime(2024, 2, 29),
          direction: direction,
        ),
        DateTime(2024 + direction, 2, 28),
      );
    }
    expect(
      ranges.shiftAnchor(
        type: PeriodType.year,
        anchor: DateTime(2024, 2, 29),
        direction: 4,
      ),
      DateTime(2028, 2, 29),
    );
  });

  test('day and week navigation use calendar dates across clock changes', () {
    // These dates also cover spring/fall clock changes when the test process
    // uses a time zone with daylight saving time, such as Europe/London.
    for (final anchor in [
      DateTime(2024, 3, 31),
      DateTime(2024, 4, 1),
      DateTime(2024, 10, 27),
      DateTime(2024, 10, 28),
      DateTime(2024, 12, 31),
    ]) {
      for (final type in [PeriodType.day, PeriodType.week]) {
        for (final direction in [-1, 1]) {
          final days = type == PeriodType.day ? direction : 7 * direction;
          expect(
            ranges.shiftAnchor(
              type: type,
              anchor: anchor,
              direction: direction,
            ),
            DateTime(anchor.year, anchor.month, anchor.day + days),
          );
        }
      }
    }
  });

  test('all-time navigation retains the anchor', () {
    final anchor = DateTime(2024, 3, 31, 12);
    expect(
      ranges.shiftAnchor(
        type: PeriodType.allTime,
        anchor: anchor,
        direction: -1,
      ),
      anchor,
    );
  });
}

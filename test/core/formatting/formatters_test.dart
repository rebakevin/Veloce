import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/formatting/formatters.dart';

void main() {
  test('rwf groups thousands with no decimals', () {
    expect(Formatters.rwf(75000), 'RWF 75,000');
    expect(Formatters.rwf(0), 'RWF 0');
  });

  test('booking reference pads to four digits', () {
    expect(Formatters.bookingReference(42), 'VLC-0042');
    expect(Formatters.bookingReference(12345), 'VLC-12345');
  });

  test('date range shows both dates', () {
    expect(
      Formatters.dateRange(DateTime(2026, 11, 9), DateTime(2026, 11, 12)),
      '9 Nov 2026 to 12 Nov 2026',
    );
  });
}

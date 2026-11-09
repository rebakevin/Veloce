import 'package:intl/intl.dart';

/// Display formats for money, dates and references.
abstract final class Formatters {
  static final NumberFormat _amount = NumberFormat.decimalPattern('en');
  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, HH:mm');

  /// `75000` -> `RWF 75,000` (no decimals).
  static String rwf(int amount) => 'RWF ${_amount.format(amount)}';

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String dateRange(DateTime start, DateTime end) =>
      '${_date.format(start)} to ${_date.format(end)}';

  /// `42` -> `VLC-0042`.
  static String bookingReference(int number) =>
      'VLC-${number.toString().padLeft(4, '0')}';
}

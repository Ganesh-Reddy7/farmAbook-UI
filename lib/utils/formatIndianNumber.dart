import 'package:intl/intl.dart';

class NumberUtils {
  static String formatIndianNumber(num value) {
    if (value >= 10000000) {
      return "${(value / 10000000).toStringAsFixed(1)}Cr";
    } else if (value >= 100000) {
      return "${(value / 100000).toStringAsFixed(1)}L";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    }
    return value.toStringAsFixed(0);
  }
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatINR(num value, {bool hideZeroDecimal = false}) {
    final formatted = _inrFormatter.format(value);
    return hideZeroDecimal
        ? formatted.replaceAll('.00', '')
        : formatted;
  }

  static String formatIndianPlain(num value) {
    final formatter = NumberFormat.decimalPattern('en_IN');
    return formatter.format(value);
  }

}

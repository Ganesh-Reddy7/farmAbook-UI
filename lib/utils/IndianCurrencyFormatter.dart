class IndianCurrencyFormatter {
  static String format(String value) {
    if (value.isEmpty) return '';
    final number = value.replaceAll(',', '');
    final parsed = double.tryParse(number);
    if (parsed == null) return value;

    final parts = parsed.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;

    for (int i = parts.length - 1; i >= 0; i--) {
      buffer.write(parts[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  static double parse(String value) =>
      double.tryParse(value.replaceAll(',', '')) ?? 0;
}

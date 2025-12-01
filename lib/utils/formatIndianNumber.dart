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
}

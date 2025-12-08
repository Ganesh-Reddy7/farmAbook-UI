import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarValuePainter extends CustomPainter {
  final List<BarChartGroupData> groups;
  final TextStyle style;
  final double minY;
  final double maxY;

  BarValuePainter({
    required this.groups,
    required this.style,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (groups.isEmpty || size.width <= 0 || size.height <= 0) return;

    final barWidth = size.width / groups.length;

    // Converts chart value to its pixel Y
    double valueToPixelY(double value) {
      final chartHeight = size.height;
      // FIX 2: Prevent division by zero
      final range = maxY - minY;
      if (range == 0) return chartHeight / 2;

      final normalized = (value - minY) / range;
      return chartHeight - (normalized * chartHeight);
    }
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (group.barRods.isEmpty) continue;

      final rod = group.barRods[0];
      final double value = rod.toY;

      if (!value.isFinite) continue;

      final double barEndY = valueToPixelY(value);
      final double zeroY = valueToPixelY(0);

      final textPainter = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(0), style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      // X position (centered above the bar)
      final double x = (i * barWidth) + (barWidth / 2) - (textPainter.width / 2);

      final double y;
      const double verticalPadding = 4;

      if (value >= 0) {
        y = barEndY - textPainter.height - verticalPadding;
      } else {
        y = barEndY - verticalPadding;
      }
      // FIX 4: More robust boundary checking
      final bool withinVerticalBounds = y >= -textPainter.height && y <= size.height + textPainter.height;
      final bool withinHorizontalBounds = x >= -textPainter.width && x <= size.width + textPainter.width;
      if (withinVerticalBounds && withinHorizontalBounds) {
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarValuePainter oldDelegate) {
    // FIX 5: Proper shouldRepaint logic for performance
    return oldDelegate.groups != groups ||
        oldDelegate.style != style ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY;
  }
}

class SingleMetricChart extends StatelessWidget {
  final List<String> years;
  final List<double> values;
  final double height;
  final Color barColor;
  final bool isDark;

  const SingleMetricChart({
    super.key,
    required this.years,
    required this.values,
    required this.isDark,
    this.height = 250,
    this.barColor = const Color(0xFF0FA958),
  });

  @override
  Widget build(BuildContext context) {
    // Check if data lists are aligned and non-empty
    if (years.isEmpty || values.isEmpty || years.length != values.length) {
      return SizedBox(
        height: height,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          child: const Center(
            child: Text(
              "No data available",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // FIX 6: Filter out invalid values (NaN, Infinity)
    final validIndices = <int>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i].isFinite) {
        validIndices.add(i);
      }
    }

    if (validIndices.isEmpty) {
      return SizedBox(
        height: height,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          child: const Center(
            child: Text(
              "Invalid data",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // FIX 7: Use only valid values for min/max calculation
    final validValues = validIndices.map((i) => values[i]).toList();
    final minVal = validValues.reduce((a, b) => a < b ? a : b);
    final maxVal = validValues.reduce((a, b) => a > b ? a : b);

    // Improve minY and maxY calculation
    final double range = maxVal - minVal;
    final double padding = range > 0 ? range * 0.1 : 1.0;

    double minY = minVal;
    double maxY = maxVal;

    // Adjust boundaries to ensure 0 is included and padding is applied
    if (minVal >= 0) {
      minY = 0;
      maxY = maxVal + padding;
    } else if (maxVal <= 0) {
      minY = minVal - padding;
      maxY = 0;
    } else {
      // Span across zero
      minY = minVal - padding;
      maxY = maxVal + padding;
    }

    // FIX 8: Better fallback for flat or near-flat data
    if ((maxY - minY).abs() < 1e-10) {
      // Data is essentially flat
      if (minY.abs() < 1e-10) {
        // Values are near zero
        minY = -5;
        maxY = 5;
      } else {
        // Values are non-zero but flat
        minY = minY - minY.abs() * 0.1;
        maxY = maxY + maxY.abs() * 0.1;
      }
    } else if (maxY - minY < 10) {
      minY = minY - 5;
      maxY = maxY + 5;
    }

    final barGroups = _buildBarGroups();

    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Stack(
        children: [
          /// CHART
          BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              alignment: BarChartAlignment.spaceAround,
              titlesData: _titles(),
              barGroups: barGroups,
              barTouchData: BarTouchData(enabled: false),
            ),
          ),

          /// LABELS
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BarValuePainter(
                  groups: barGroups,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  minY: minY,
                  maxY: maxY,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- TITLES ----------
  FlTitlesData _titles() {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          reservedSize: 32,
          showTitles: true,
          getTitlesWidget: (value, _) {
            int index = value.toInt();
            if (index < 0 || index >= years.length) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                years[index],
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------- BAR GROUPS ----------
  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(years.length, (i) {
      final double y = values[i];

      // FIX 9: Handle invalid values in bar generation
      final double safeY = y.isFinite ? y : 0;
      final bool isPositive = safeY >= 0;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: safeY,
            width: 18,
            // FIX 10: Simplified color application (no need for rodStackItems for single color)
            color: barColor,
            // Apply rounded corners correctly based on direction
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isPositive ? 6 : 0),
              topRight: Radius.circular(isPositive ? 6 : 0),
              bottomLeft: Radius.circular(isPositive ? 0 : 6),
              bottomRight: Radius.circular(isPositive ? 0 : 6),
            ),
          ),
        ],
      );
    });
  }
}
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CommonBarChart extends StatefulWidget {
  final bool isDark;
  final Color chartBg;
  final List<String> labels;

  final List<double> values; // dataset 1
  final List<double>? values2; // dataset 2 (optional)

  final Color barColor;
  final Color barColor2;

  final double barWidth;
  final double height;

  final String? legend1;
  final String? legend2;

  const CommonBarChart({
    Key? key,
    required this.isDark,
    required this.chartBg,
    required this.labels,
    required this.values,
    this.values2,
    this.legend1,
    this.legend2,
    this.barColor = Colors.blueAccent,
    this.barColor2 = Colors.orangeAccent,
    this.barWidth = 20,
    this.height = 270,
  }) : super(key: key);

  @override
  State<CommonBarChart> createState() => _CommonBarChartState();
}

class _CommonBarChartState extends State<CommonBarChart> with SingleTickerProviderStateMixin{
  bool show1 = true;
  bool show2 = true;

  // Clean Y axis steps
  double _roundMaxY(double value) {
    if (value <= 10) return 10;
    if (value <= 50) return 50;
    if (value <= 100) return 100;
    if (value <= 200) return 200;
    if (value <= 500) return 500;
    return (value / 100).ceil() * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // Combine values safely
    final allValues = [
      ...widget.values,
      if (widget.values2 != null) ...widget.values2!,
    ];

    // SAFE: prevent reduce() crash
    final double maxValue =
    allValues.isEmpty ? 0 : allValues.reduce((a, b) => a > b ? a : b);

    final double yMax = _roundMaxY(maxValue);
    final double interval = yMax == 0 ? 1 : yMax / 5;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),

      child: Column(
        children: [
          _buildLegendInside(),
          const SizedBox(height: 8),

          SizedBox(
            height: widget.height - 40,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: yMax,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                alignment: BarChartAlignment.spaceAround,
                titlesData: _buildTitles(interval),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitles(double interval) {
    final isDark = widget.isDark;

    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          reservedSize: 40,
          showTitles: true,
          interval: interval,
          getTitlesWidget: (value, _) => Text(
            value.toInt().toString(),
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ),
      ),

      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          reservedSize: 36,
          showTitles: true,
          getTitlesWidget: (value, _) {
            int i = value.toInt();
            if (i < 0 || i >= widget.labels.length) {
              return const SizedBox();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.labels[i],
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            );
          },
        ),
      ),

      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  // -----------------------------------
  // SAFE BAR GROUPS (No Index Crash)
  // -----------------------------------
  List<BarChartGroupData> _buildBarGroups() {
    final v1 = widget.values;
    final v2 = widget.values2;

    final groups = <BarChartGroupData>[];

    for (int i = 0; i < widget.labels.length; i++) {
      final rods = <BarChartRodData>[];

      if (show1 && i < v1.length) {
        rods.add(
          BarChartRodData(
            toY: v1[i],
            width: widget.barWidth,
            color: widget.barColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }

      if (show2 && v2 != null && i < v2.length) {
        rods.add(
          BarChartRodData(
            toY: v2[i],
            width: widget.barWidth,
            color: widget.barColor2,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }

      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: rods.length > 1 ? 6 : 0,
          barRods: rods,
        ),
      );
    }

    return groups;
  }

  // -----------------------------------
  // LEGEND INSIDE
  // -----------------------------------
  Widget _buildLegendInside() {
    if (widget.legend1 == null && widget.legend2 == null) {
      return const SizedBox();
    }

    final isDark = widget.isDark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.legend1 != null)
          GestureDetector(
            onTap: () => setState(() => show1 = !show1),
            child: Row(
              children: [
                _legendDot(widget.barColor.withOpacity(show1 ? 1 : 0.25)),
                const SizedBox(width: 6),
                Text(
                  widget.legend1!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? (show1 ? Colors.white70 : Colors.white24)
                        : (show1 ? Colors.black87 : Colors.black26),
                  ),
                ),
              ],
            ),
          ),

        if (widget.legend2 != null) ...[
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => setState(() => show2 = !show2),
            child: Row(
              children: [
                _legendDot(widget.barColor2.withOpacity(show2 ? 1 : 0.25)),
                const SizedBox(width: 6),
                Text(
                  widget.legend2!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? (show2 ? Colors.white70 : Colors.white24)
                        : (show2 ? Colors.black87 : Colors.black26),
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _legendDot(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

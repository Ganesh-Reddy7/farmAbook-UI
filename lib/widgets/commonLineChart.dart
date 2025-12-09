import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CommonLineChart extends StatefulWidget {
  final bool isDark;

  final List<String> labels;
  final List<double> values;
  final List<double>? values2;

  final String? legend1;
  final String? legend2;

  final Color lineColor1;
  final Color lineColor2;

  final double height;

  const CommonLineChart({
    Key? key,
    required this.isDark,
    required this.labels,
    required this.values,
    this.values2,
    this.legend1,
    this.legend2,
    this.lineColor1 = Colors.blueAccent,
    this.lineColor2 = Colors.orangeAccent,
    this.height = 220,
  }) : super(key: key);

  @override
  State<CommonLineChart> createState() => _CommonLineChartState();
}

class _CommonLineChartState extends State<CommonLineChart> {
  bool show1 = true;
  bool show2 = true;

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

    final allValues = [
      ...widget.values,
      if (widget.values2 != null) ...widget.values2!,
    ];

    final double maxValue =
    allValues.isEmpty ? 0 : allValues.reduce((a, b) => a > b ? a : b);

    final double yMax = _roundMaxY(maxValue);
    final double interval = yMax / 5;

    return Container(
      padding: const EdgeInsets.all(16),
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
          _buildLegend(),
          const SizedBox(height: 12),

          SizedBox(
            height: widget.height,
            child: LineChart(
              _chartData(yMax, interval),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(double yMax, double interval) {
    final isDark = widget.isDark;

    return LineChartData(
      minY: 0,
      maxY: yMax,

      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          );
        },
        drawVerticalLine: false,
      ),

      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            reservedSize: 40,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
              getTitlesWidget: (value, _) {
                if (value % 1 != 0) {
                  return const SizedBox();
                }
                int index = value.toInt();
                if (index < 0 || index >= widget.labels.length) {
                  return const SizedBox();
                }
                return Text(
                  widget.labels[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                );
              },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      // TOOLTIP
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipMargin: 12,
          fitInsideHorizontally: true,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                "${spot.y.toStringAsFixed(2)}",
                TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              );
            }).toList();
          },
        ),
      ),

      lineBarsData: _buildLines(),
    );
  }

  List<LineChartBarData> _buildLines() {
    final lines = <LineChartBarData>[];

    if (show1) {
      lines.add(LineChartBarData(
        spots: [
          for (int i = 0; i < widget.values.length; i++)
            FlSpot(i.toDouble(), widget.values[i]),
        ],
        isCurved: true,
        color: widget.lineColor1,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              widget.lineColor1.withOpacity(0.3),
              widget.lineColor1.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ));
    }

    if (widget.values2 != null && show2) {
      lines.add(LineChartBarData(
        spots: [
          for (int i = 0; i < widget.values2!.length; i++)
            FlSpot(i.toDouble(), widget.values2![i]),
        ],
        isCurved: true,
        color: widget.lineColor2,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              widget.lineColor2.withOpacity(0.3),
              widget.lineColor2.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ));
    }

    return lines;
  }


  Widget _buildLegend() {
    final isDark = widget.isDark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.legend1 != null)
          GestureDetector(
            onTap: () => setState(() => show1 = !show1),
            child: Row(
              children: [
                _legendDot(widget.lineColor1.withOpacity(show1 ? 1 : 0.25)),
                const SizedBox(width: 6),
                Text(
                  widget.legend1!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? (show1 ? Colors.white : Colors.white30)
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
                _legendDot(widget.lineColor2.withOpacity(show2 ? 1 : 0.25)),
                const SizedBox(width: 6),
                Text(
                  widget.legend2!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? (show2 ? Colors.white : Colors.white30)
                        : (show2 ? Colors.black87 : Colors.black26),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _legendDot(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

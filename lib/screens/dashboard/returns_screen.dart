import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReturnsScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const ReturnsScreen({
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.scaffoldBg,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
    Key? key,
  }) : super(key: key);

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final Map<int, double> yearlyInvestments = {
    2019: 50000,
    2020: 75000,
    2021: 60000,
    2022: 85000,
    2023: 95000,
  };

  final Map<int, double> yearlyReturns = {
    2019: 4000,
    2020: 6500,
    2021: 5000,
    2022: 7000,
    2023: 9000,
  };

  int _selectedYear = 2023;
  bool _showLineChart = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title + chart toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Investment & Returns",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showLineChart ? Icons.bar_chart : Icons.show_chart,
                    color: widget.accent,
                  ),
                  onPressed: () {
                    setState(() {
                      _showLineChart = !_showLineChart;
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 16),

            // Year selection dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select Year:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.primaryText,
                  ),
                ),
                DropdownButton<int>(
                  dropdownColor: Colors.black87,
                  value: _selectedYear,
                  items: yearlyInvestments.keys.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: TextStyle(color: widget.primaryText),
                      ),
                    );
                  }).toList(),
                  onChanged: (year) {
                    setState(() {
                      _selectedYear = year!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chart
            Expanded(
              child: _showLineChart ? _buildNeonLineChart() : _buildNeonBarChart(),
            ),

            const SizedBox(height: 12),

            // Selected year investments and returns
            Column(
              children: [
                Text(
                  "Investments in $_selectedYear: ₹${yearlyInvestments[_selectedYear]}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Returns in $_selectedYear: ₹${yearlyReturns[_selectedYear]}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Neon Line Chart
  Widget _buildNeonLineChart() {
    final maxY = (yearlyInvestments.values
        .reduce((a, b) => a > b ? a : b) +
        yearlyReturns.values.reduce((a, b) => a > b ? a : b)) *
        1.2;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: yearlyInvestments.length - 1.toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.08),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                int year = 2019 + value.toInt();
                return Text(
                  year.toString(),
                  style: TextStyle(color: widget.primaryText, fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: widget.primaryText, fontSize: 12),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: yearlyInvestments.entries
                .map((e) => FlSpot((e.key - 2019).toDouble(), e.value))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [widget.accent, Colors.greenAccent.shade200],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: widget.accent,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  widget.accent.withOpacity(0.3),
                  widget.accent.withOpacity(0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: yearlyReturns.entries
                .map((e) => FlSpot((e.key - 2019).toDouble(), e.value))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.redAccent],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.orangeAccent,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.orangeAccent.withOpacity(0.3),
                  Colors.orangeAccent.withOpacity(0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Neon Bar Chart
  Widget _buildNeonBarChart() {
    final maxY = (yearlyInvestments.values
        .reduce((a, b) => a > b ? a : b) +
        yearlyReturns.values.reduce((a, b) => a > b ? a : b)) *
        1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withOpacity(0.08), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                int year = 2019 + value.toInt();
                return Text(
                  year.toString(),
                  style: TextStyle(color: widget.primaryText, fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: widget.primaryText, fontSize: 12),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: yearlyInvestments.entries.map((entry) {
          final returnsValue = yearlyReturns[entry.key] ?? 0;
          return BarChartGroupData(
            x: entry.key - 2019,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                width: 14,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [widget.accent, Colors.greenAccent.shade200],
                ),
              ),
              BarChartRodData(
                toY: returnsValue,
                width: 14,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [Colors.orangeAccent, Colors.redAccent],
                ),
              ),
            ],
            barsSpace: 4,
          );
        }).toList(),
      ),
    );
  }
}

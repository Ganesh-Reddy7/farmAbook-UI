import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const SummaryScreen({
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
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
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
  bool _showBarChart = true;

  // Dynamic calculation of reservedSize for Y-axis labels
  double getReservedYTitleSize(double maxY, TextStyle style) {
    final text = "₹${maxY.toInt()}";
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width + 8; // small padding
  }

  @override
  @override
  Widget build(BuildContext context) {
    final maxY = ([...yearlyInvestments.values, ...yearlyReturns.values]
        .reduce((a, b) => a > b ? a : b)) *
        1.2;

    final yLabelStyle = TextStyle(color: widget.primaryText, fontSize: 12);
    final reservedSize = getReservedYTitleSize(maxY, yLabelStyle);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  "Summary (Investment & Returns)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showBarChart = !_showBarChart),
                icon: Icon(
                  _showBarChart ? Icons.show_chart : Icons.bar_chart,
                  color: widget.accent,
                ),
                tooltip: _showBarChart ? "Switch to Line Chart" : "Switch to Bar Chart",
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart (give fixed height so it doesn't expand infinitely)
          SizedBox(
            height: 250,
            child: _showBarChart
                ? _buildNeonBarChart(maxY, reservedSize, yLabelStyle)
                : _buildNeonLineChart(maxY, reservedSize, yLabelStyle),
          ),

          const SizedBox(height: 16),

          // Year selection
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
                    child: Text(year.toString(), style: TextStyle(color: widget.primaryText)),
                  );
                }).toList(),
                onChanged: (year) => setState(() => _selectedYear = year!),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pie Chart
          _buildInvestmentReturnPieChart(),

          const SizedBox(height: 16),

          // Selected year investments & returns
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
          ),
        ],
      ),
    );
  }


  // Neon Line Chart
  Widget _buildNeonLineChart(double maxY, double reservedSize, TextStyle yLabelStyle) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: yearlyInvestments.length - 1.toDouble(),
        minY: 0,
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
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                int year = 2019 + value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(year.toString(), style: yLabelStyle),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: reservedSize,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text("₹${value.toInt()}", style: yLabelStyle, textAlign: TextAlign.right),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          // Investment line
          LineChartBarData(
            spots: yearlyInvestments.entries
                .map((e) => FlSpot((e.key - 2019).toDouble(), e.value))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(colors: [widget.accent, Colors.greenAccent.shade200]),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(radius: 5, color: widget.accent, strokeWidth: 2, strokeColor: Colors.white),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [widget.accent.withOpacity(0.3), widget.accent.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Returns line
          LineChartBarData(
            spots: yearlyReturns.entries
                .map((e) => FlSpot((e.key - 2019).toDouble(), e.value))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(colors: [Colors.orangeAccent, Colors.redAccent]),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(radius: 5, color: Colors.orangeAccent, strokeWidth: 2, strokeColor: Colors.white),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.orangeAccent.withOpacity(0.3), Colors.orangeAccent.withOpacity(0.0)],
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
  Widget _buildNeonBarChart(double maxY, double reservedSize, TextStyle yLabelStyle) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
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
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                int year = 2019 + value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(year.toString(), style: yLabelStyle),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: reservedSize,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text("₹${value.toInt()}", style: yLabelStyle, textAlign: TextAlign.right),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: yearlyInvestments.entries.map((entry) {
          final returnsValue = yearlyReturns[entry.key] ?? 0;
          return BarChartGroupData(
            x: entry.key - 2019,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                width: 14,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(colors: [widget.accent, Colors.greenAccent.shade200]),
              ),
              BarChartRodData(
                toY: returnsValue,
                width: 14,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(colors: [Colors.orangeAccent, Colors.redAccent]),
              ),
            ],
            barsSpace: 4,
          );
        }).toList(),
      ),
    );
  }

  // Pie chart for selected year
  // Pie chart for selected year
  Widget _buildInvestmentReturnPieChart() {
    final investment = yearlyInvestments[_selectedYear] ?? 0;
    final returns = yearlyReturns[_selectedYear] ?? 0;

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: investment,
              color: widget.accent,
              title: "₹${investment.toInt()}",
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            ),
            PieChartSectionData(
              value: returns,
              color: Colors.orangeAccent,
              title: "₹${returns.toInt()}",
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            ),
          ],
        ),
      ),
    );
  }


}

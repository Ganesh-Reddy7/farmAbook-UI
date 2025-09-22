import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_entities/add_investment_screen.dart' hide Worker;
import 'worker_list_screen.dart';
import '../../../models/investment.dart';

class InvestmentsScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const InvestmentsScreen({
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
  _InvestmentsScreenState createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isLineChart = false;

  Map<int, List<Investment>> investmentsByYear = {
    2023: [
      Investment(id: 1, date: DateTime(2023, 3, 12), description: "Fertilizer purchase", amount: 5000),
      Investment(id: 2, date: DateTime(2023, 5, 18), description: "Seed purchase", amount: 3000, workers: [
        Worker(name: "Raju", wage: 500, role: "Seeder"),
      ]),
    ],
    2022: [
      Investment(id: 3, date: DateTime(2022, 2, 10), description: "Irrigation setup", amount: 8000),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final currentYearInvestments = investmentsByYear[_selectedYear] ?? [];

    // Calculate total investment for selected year
    final totalInvestment = currentYearInvestments.fold<double>(0.0, (sum, inv) => sum + inv.amount);

    // Prepare yearly totals for chart (all years starting from 2019)
    final yearlyInvestments = <int, double>{};
    for (int year = 2019; year <= DateTime.now().year; year++) {
      yearlyInvestments[year] = investmentsByYear[year]?.fold<double>(0, (sum, inv) => sum + inv.amount) ?? 0;
    }

    final maxY = yearlyInvestments.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text(
          "Investments",
          style: TextStyle(color: widget.primaryText, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(_isLineChart ? Icons.bar_chart : Icons.show_chart, color: widget.accent),
            onPressed: () {
              setState(() => _isLineChart = !_isLineChart);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: _isLineChart ? _buildLineChart(yearlyInvestments, maxY) : _buildBarChart(yearlyInvestments, maxY),
              ),

            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select Year:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: widget.primaryText),
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
                  onChanged: (year) {
                    setState(() => _selectedYear = year!);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              "Investments in $_selectedYear : ₹${totalInvestment.toStringAsFixed(0)}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.primaryText),
            ),

            const SizedBox(height: 20),

            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: currentYearInvestments.length,
              itemBuilder: (context, index) {
                final inv = currentYearInvestments[index];
                return GestureDetector(
                  onTap: () {
                    if (inv.workers != null && inv.workers!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkerListScreen(
                            investment: inv,
                            accent: widget.accent,
                            primaryText: widget.primaryText,
                            secondaryText: widget.secondaryText,
                            scaffoldBg: widget.scaffoldBg,
                            cardGradientStart: widget.cardGradientStart,
                            cardGradientEnd: widget.cardGradientEnd,
                            cardBorder: widget.cardBorder,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          widget.cardGradientStart.withOpacity(0.3),
                          widget.cardGradientEnd.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: widget.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.description, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.primaryText)),
                            const SizedBox(height: 4),
                            Text(
                              "Date: ${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}-${inv.date.day.toString().padLeft(2, '0')}",
                              style: TextStyle(color: widget.secondaryText),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("₹${inv.amount}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.accent)),
                            if (inv.workers != null && inv.workers!.isNotEmpty) Icon(Icons.people, color: widget.accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: widget.accent,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddInvestmentScreen(
                scaffoldBg: widget.scaffoldBg,
                primaryText: widget.primaryText,
                secondaryText: widget.secondaryText,
                accent: widget.accent,
                cardGradientStart: widget.cardGradientStart,
                cardGradientEnd: widget.cardGradientEnd,
                cardBorder: widget.cardBorder,
              ),
            ),
          );

          if (result == true) {
            setState(() {
              investmentsByYear[_selectedYear]?.add(
                Investment(
                  id: DateTime.now().millisecondsSinceEpoch,
                  date: DateTime.now(),
                  description: "New Investment",
                  amount: 1000,
                ),
              );
            });
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBarChart(Map<int, double> yearlyInvestments, double maxY) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int year = 2019 + value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(year.toString(), style: TextStyle(color: widget.primaryText, fontSize: 12)),
                );
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Text("₹${value.toInt()}", style: TextStyle(color: widget.primaryText, fontSize: 12), textAlign: TextAlign.right),
              ),
              reservedSize: 50,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: yearlyInvestments.entries
            .map((entry) => BarChartGroupData(
          x: entry.key - 2019,
          barRods: [
            BarChartRodData(toY: entry.value, color: widget.accent, width: 18, borderRadius: BorderRadius.circular(6))
          ],
        ))
            .toList(),
      ),
    );
  }

  Widget _buildLineChart(Map<int, double> yearlyInvestments, double maxY) {
    return LineChart(
      LineChartData(
        maxY: maxY,
        lineTouchData: LineTouchData(enabled: true),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int year = 2019 + value.toInt();
                return Text(year.toString(), style: TextStyle(color: widget.primaryText, fontSize: 12));
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text("₹${value.toInt()}", style: TextStyle(color: widget.primaryText, fontSize: 12), textAlign: TextAlign.right),
              ),
              reservedSize: 55,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: yearlyInvestments.entries
                .map((e) => FlSpot((e.key - 2019).toDouble(), e.value))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(colors: [widget.accent.withOpacity(0.5), widget.accent]),
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [widget.accent.withOpacity(0.2), Colors.transparent])),
          ),
        ],
      ),
    );
  }
}

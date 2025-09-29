import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/investment.dart';
import '../../services/investment_service.dart';
import 'add_entities/add_investment_screen.dart' hide Worker;
import 'worker_list_screen.dart';

class InvestmentsScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;
  final VoidCallback? onDataChanged;

  const InvestmentsScreen({
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.scaffoldBg,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
    this.onDataChanged, // <-- add this
    Key? key,
  }) : super(key: key);

  @override
  _InvestmentsScreenState createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isLineChart = false;

  Map<int, List<Investment>> investmentsByYear = {};
  Map<int, double> yearlyInvestments = {};

  @override
  void initState() {
    super.initState();
    _fetchYearlySummary();
    _fetchInvestmentsForYear(_selectedYear, true);
  }

  Future<void> _fetchYearlySummary() async {
    final fetched = await InvestmentService().getYearlySummaryForFarmer(
      startYear: DateTime.now().year - 4,
      endYear: DateTime.now().year + 1,
    );
    setState(() {
      yearlyInvestments = {for (var e in fetched) e.year: e.totalAmount};
    });
  }

  Future<void> _fetchInvestmentsForYear(int year, bool includeWorkers) async {
    final fetched = await InvestmentService().getInvestmentsByFinancialYear(
      year: year,
      includeWorkers: includeWorkers,
    );
    setState(() {
      investmentsByYear[year] = fetched;
    });
  }

  Future<void> _refreshCurrentYearInvestments() async {
    await _fetchInvestmentsForYear(_selectedYear, true);
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  double safeMaxY(double value) => value > 0 ? value * 1.2 : 1000;

  double get maxY {
    return yearlyInvestments.isEmpty
        ? 1000
        : safeMaxY(yearlyInvestments.values.reduce(max));
  }

  TextStyle get yLabelStyle => TextStyle(color: widget.primaryText, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    final currentYearInvestments = investmentsByYear[_selectedYear] ?? [];
    final totalInvestment = currentYearInvestments.fold<double>(
      0.0,
          (sum, inv) => sum + inv.amount,
    );
    final totalRemaining = currentYearInvestments.fold<double>(
      0.0,
          (sum, inv) => sum + (inv.remainingAmount ?? 0.0),
    );
    final lastFiveYears =
    List.generate(5, (i) => DateTime.now().year - i).reversed.toList();

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text(
          "Investments",
          style: TextStyle(
            color: widget.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isLineChart ? Icons.bar_chart : Icons.show_chart,
              color: widget.accent,
            ),
            onPressed: () => setState(() => _isLineChart = !_isLineChart),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCurrentYearInvestments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Yearly chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: SizedBox(
                  height: 250,
                  child: yearlyInvestments.isEmpty
                      ? Center(
                    child: Text(
                      "No chart data available",
                      style: TextStyle(
                        color: widget.secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : _isLineChart
                      ? _buildLineChart(yearlyInvestments, lastFiveYears)
                      : _buildBarChart(yearlyInvestments, lastFiveYears),
                ),
              ),
              const SizedBox(height: 20),
              // Year dropdown
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
                    items: lastFiveYears
                        .map((year) => DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: TextStyle(color: widget.primaryText),
                      ),
                    ))
                        .toList(),
                    onChanged: (year) {
                      if (year != null) {
                        setState(() => _selectedYear = year);
                        _fetchInvestmentsForYear(year, true);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Total and Pending card
              _totalAndPendingCard(totalInvestment, totalRemaining),
              const SizedBox(height: 20),
              // Pie chart
              _investmentPieChart(currentYearInvestments, totalInvestment),
              const SizedBox(height: 20),
              // Investment list
              currentYearInvestments.isEmpty
                  ? _noInvestmentsCard()
                  : Column(
                children: currentYearInvestments
                    .map((inv) => _investmentCard(inv))
                    .toList(),
              ),
            ],
          ),
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
          if (result == true) _refreshCurrentYearInvestments();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _totalAndPendingCard(double total, double pending) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            widget.cardGradientStart.withOpacity(0.1),
            widget.cardGradientEnd.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _totalPendingColumn(
              icon: Icons.account_balance_wallet,
              iconBg: widget.accent.withOpacity(0.2),
              amount: total,
              title: "Total Investment",
              amountColor: widget.accent),
          Container(width: 1, height: 60, color: widget.cardBorder.withOpacity(0.3)),
          _totalPendingColumn(
              icon: Icons.pending_actions,
              iconBg: Colors.orange.withOpacity(0.2),
              amount: pending,
              title: "Pending Amount",
              amountColor: Colors.orange.shade700),
        ],
      ),
    );
  }

  Column _totalPendingColumn(
      {required IconData icon,
        required Color iconBg,
        required double amount,
        required String title,
        required Color amountColor}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: amountColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: widget.secondaryText)),
        const SizedBox(height: 4),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor),
        ),
      ],
    );
  }

  Widget _investmentPieChart(List<Investment> investments, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: widget.cardGradientStart.withOpacity(0.05),
        border: Border.all(color: widget.cardBorder),
      ),
      child: SizedBox(
        height: 220,
        child: investments.isEmpty
            ? Center(
          child: Text(
            "No pie chart data available",
            style: TextStyle(
                color: widget.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        )
            : PieChart(
          PieChartData(
            sections: investments.map((inv) {
              final percentage = total > 0 ? (inv.amount / total) * 100 : 0.0;
              return PieChartSectionData(
                value: inv.amount,
                color: Colors.primaries[investments.indexOf(inv) % Colors.primaries.length],
                title:
                "${inv.description}\n₹${inv.amount.toStringAsFixed(0)}\n${percentage.toStringAsFixed(1)}%",
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }

  Widget _noInvestmentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.cardGradientStart.withOpacity(0.1),
            widget.cardGradientEnd.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 40, color: widget.accent),
          const SizedBox(height: 12),
          Text(
            "No investments available",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: widget.secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            "Please add investments to view details.",
            style: TextStyle(color: widget.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _investmentCard(Investment inv) {
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
      child: SizedBox(
        width: double.infinity,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.cardGradientStart.withOpacity(0.1),
                widget.cardGradientEnd.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                color: widget.scaffoldBg.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: investment details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.description,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.primaryText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Date: ${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}-${inv.date.day.toString().padLeft(2, '0')}",
                          style: TextStyle(color: widget.secondaryText),
                        ),
                        if (inv.remainingAmount != null) ...[
                          const SizedBox(height: 4),
                          if (inv.remainingAmount! > 0)
                            Text(
                              "Remaining: ₹${inv.remainingAmount!.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade700,
                              ),
                            )
                          else
                            Text(
                              "Fully Paid ✅",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade600,
                              ),
                            ),
                        ],
                      ],
                    ),
                    // Right: amount and workers
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${inv.amount.toStringAsFixed(0)}",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.accent),
                        ),
                        if (inv.workers != null && inv.workers!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Icon(Icons.people, color: widget.accent),
                        ]
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<int, double> yearlyInvestments, List<int> lastFiveYears) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= lastFiveYears.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(lastFiveYears[index].toString(), style: yLabelStyle),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Text("₹${value.toInt()}", style: yLabelStyle, textAlign: TextAlign.right),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(lastFiveYears.length, (index) {
          int year = lastFiveYears[index];
          double value = yearlyInvestments[year] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [BarChartRodData(toY: value, color: widget.accent, width: 18, borderRadius: BorderRadius.circular(6))],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(Map<int, double> yearlyInvestments, List<int> lastFiveYears) {
    final spots = List.generate(lastFiveYears.length, (index) {
      int year = lastFiveYears[index];
      double value = yearlyInvestments[year] ?? 0;
      return FlSpot(index.toDouble(), value);
    });

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineTouchData: LineTouchData(enabled: true),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= lastFiveYears.length) return const SizedBox();
                return Text(lastFiveYears[index].toString(), style: yLabelStyle);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 55,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 0),
                child: Text("₹${value.toInt()}", style: yLabelStyle, textAlign: TextAlign.right),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: [widget.accent.withOpacity(0.5), widget.accent]),
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [widget.accent.withOpacity(0.2), Colors.transparent]),
            ),
          ),
        ],
      ),
    );
  }
}

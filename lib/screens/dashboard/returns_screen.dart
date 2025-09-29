import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/return_model.dart';
import '../../services/return_service.dart';
import 'add_entities/add_returns_screen.dart';
import 'detail_screens/return_details_screen.dart';

class ReturnsScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;
  final VoidCallback? onDataChanged;

  const ReturnsScreen({
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
  _ReturnsScreenState createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isLineChart = false;

  Map<int, List<ReturnsList>> returnsByYear = {};
  Map<int, double> yearlyReturns = {};

  @override
  void initState() {
    super.initState();
    _fetchYearlySummary();
    _fetchReturnsForYear(_selectedYear);
  }

  Future<void> _fetchYearlySummary() async {
    final fetched = await ReturnService().getYearlySummary(years: 5);
    setState(() {
      yearlyReturns = {for (var e in fetched) e.year: e.totalAmount};
    });
  }

  Future<void> _fetchReturnsForYear(int year) async {
    final fetched = await ReturnService().getReturnsByYear(year: year);
    setState(() {
      returnsByYear[year] = fetched;
    });
  }

  Future<void> _refreshCurrentYearReturns() async {
    await _fetchReturnsForYear(_selectedYear);
    // Notify parent (DashboardScreen) to refresh top cards
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  double safeMaxY(double value) => value > 0 ? value * 1.2 : 1000;

  double get maxY {
    return yearlyReturns.isEmpty
        ? 1000
        : safeMaxY(yearlyReturns.values.reduce(max));
  }

  TextStyle get yLabelStyle => TextStyle(color: widget.primaryText, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    final currentYearReturns = returnsByYear[_selectedYear] ?? [];
    final totalReturns = currentYearReturns.fold<double>(
        0.0, (sum, ret) => sum + ret.totalReturns);
    final lastFiveYears =
    List.generate(5, (i) => DateTime.now().year - i).reversed.toList();

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text(
          "Returns",
          style: TextStyle(
              color: widget.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 20),
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
        onRefresh: _refreshCurrentYearReturns,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Yearly Chart Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: SizedBox(
                  height: 250,
                  child: yearlyReturns.isEmpty
                      ? Center(
                    child: Text(
                      "No chart data available",
                      style: TextStyle(
                          color: widget.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                      : _isLineChart
                      ? _buildLineChart(yearlyReturns, lastFiveYears)
                      : _buildBarChart(yearlyReturns, lastFiveYears),
                ),
              ),
              const SizedBox(height: 20),
              // Year Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Year:",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.primaryText),
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
                        _fetchReturnsForYear(year);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Total Returns Section
              Container(
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.accent.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.savings,
                                  color: widget.accent, size: 28),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Total Returns",
                              style: TextStyle(
                                  fontSize: 14, color: widget.secondaryText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${totalReturns.toStringAsFixed(0)}",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: widget.accent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Pie Chart
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: SizedBox(
                  height: 220,
                  child: currentYearReturns.isEmpty
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
                      sections: currentYearReturns.map((ret) {
                        final percentage = totalReturns > 0
                            ? (ret.totalReturns / totalReturns) * 100
                            : 0.0;
                        return PieChartSectionData(
                          value: ret.totalReturns,
                          color: Colors.primaries[
                          currentYearReturns.indexOf(ret) %
                              Colors.primaries.length],
                          title:
                          "${ret.cropName}\n₹${ret.totalReturns.toStringAsFixed(0)}\n${percentage.toStringAsFixed(1)}%",
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
              ),
              const SizedBox(height: 20),
              // Returns List with navigation
              currentYearReturns.isEmpty
                  ? Container(
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
                  border:
                  Border.all(color: widget.cardBorder.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        size: 40, color: widget.accent),
                    const SizedBox(height: 12),
                    Text(
                      "No returns available",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.secondaryText),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Please add returns to view details.",
                      style: TextStyle(color: widget.secondaryText),
                    ),
                  ],
                ),
              )
                  : Column(
                children: currentYearReturns.map((ret) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReturnDetailsScreen(
                            crop: ret,
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
                          border: Border.all(
                              color: widget.cardBorder.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter:
                            ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              color: widget.scaffoldBg.withOpacity(0.5),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ret.cropName,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: widget.primaryText),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Total Production: ${ret.totalProduction}",
                                        style: TextStyle(
                                            color: widget.secondaryText),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "₹${ret.totalReturns.toStringAsFixed(0)}",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: widget.accent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
              builder: (_) => AddReturnScreen(
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
          if (result == true) _refreshCurrentYearReturns();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBarChart(Map<int, double> yearlyReturns, List<int> lastFiveYears) {
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
                if (index < 0 || index >= lastFiveYears.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    lastFiveYears[index].toString(),
                    style: yLabelStyle,
                  ),
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
                child: Text(
                  "₹${value.toInt()}",
                  style: yLabelStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(lastFiveYears.length, (index) {
          int year = lastFiveYears[index];
          double value = yearlyReturns[year] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: widget.accent,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              )
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(Map<int, double> yearlyReturns, List<int> lastFiveYears) {
    final spots = List.generate(lastFiveYears.length, (index) {
      int year = lastFiveYears[index];
      double value = yearlyReturns[year] ?? 0;
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
                if (index < 0 || index >= lastFiveYears.length) {
                  return const SizedBox();
                }
                return Text(
                  lastFiveYears[index].toString(),
                  style: yLabelStyle,
                );
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
                child: Text(
                  "₹${value.toInt()}",
                  style: yLabelStyle,
                  textAlign: TextAlign.right,
                ),
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
            gradient: LinearGradient(
              colors: [widget.accent.withOpacity(0.5), widget.accent],
            ),
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [widget.accent.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------- ReturnsScreen.dart -------------------
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
  }

  double safeMaxY(double value) => value > 0 ? value * 1.2 : 1000;

  // -------------------- Glassmorphic Card with No Data --------------------
  Widget _glassCardNoData(String message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: widget.cardGradientStart.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 40, color: widget.accent),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentYearReturns = returnsByYear[_selectedYear] ?? [];
    final totalReturn = currentYearReturns.fold<double>(
        0.0, (sum, ret) => sum + ret.totalReturns);
    final lastFiveYears =
    List.generate(5, (i) => DateTime.now().year - i).reversed.toList();
    double maxY = safeMaxY(yearlyReturns.values.isNotEmpty
        ? yearlyReturns.values.reduce(max)
        : 0);

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
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCurrentYearReturns,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // -------------------- Yearly Chart --------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: SizedBox(
                  height: 250,
                  child: yearlyReturns.isEmpty
                      ? _glassCardNoData("No yearly returns data")
                      : _isLineChart
                      ? _buildLineChart(yearlyReturns, maxY, lastFiveYears)
                      : _buildBarChart(yearlyReturns, maxY, lastFiveYears),
                ),
              ),

              const SizedBox(height: 20),

              // -------------------- Year Dropdown --------------------
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
                      child: Text(year.toString(),
                          style: TextStyle(color: widget.primaryText)),
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

              // -------------------- Pie Chart --------------------
              currentYearReturns.isEmpty
                  ? _glassCardNoData("No returns to display")
                  : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(currentYearReturns),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: currentYearReturns.map((ret) {
                        final color = Colors.primaries[
                        currentYearReturns.indexOf(ret) %
                            Colors.primaries.length];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${ret.cropName}: ₹${ret.totalReturns.toStringAsFixed(0)}",
                              style: TextStyle(color: widget.primaryText),
                            ),
                          ],
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -------------------- Total Returns Section --------------------
              currentYearReturns.isEmpty
                  ? _glassCardNoData("No returns to display")
                  : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.savings, color: widget.accent, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Returns",
                          style: TextStyle(
                              fontSize: 14,
                              color: widget.secondaryText,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "₹${totalReturn.toStringAsFixed(0)}",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.accent),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "in $_selectedYear",
                          style: TextStyle(
                              fontSize: 12,
                              color: widget.primaryText,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -------------------- Returns List --------------------
              currentYearReturns.isEmpty
                  ? _glassCardNoData("No returns to display")
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
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                        border: Border.all(
                            color: widget.cardBorder.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: TextStyle(color: widget.secondaryText),
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
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: FloatingActionButton(
              elevation: 0,
              backgroundColor: Colors.transparent,
              mini: true,
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
              child: const Icon(Icons.create, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- Pie Chart Sections --------------------
  List<PieChartSectionData> _buildPieSections(List<ReturnsList> returns) {
    return returns.map((ret) {
      final color = Colors.primaries[returns.indexOf(ret) % Colors.primaries.length];
      return PieChartSectionData(
        color: color,
        value: ret.totalReturns,
        radius: 70,
        title: "₹${ret.totalReturns.toStringAsFixed(0)}",
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: widget.primaryText,
        ),
      );
    }).toList();
  }

  // -------------------- Bar Chart --------------------
  Widget _buildBarChart(Map<int, double> yearlyReturns, double maxY, List<int> lastFiveYears) {
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
                  child: Text(lastFiveYears[index].toString(),
                      style: TextStyle(color: widget.primaryText, fontSize: 12)),
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
                  style: TextStyle(color: widget.primaryText, fontSize: 12),
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
                  borderRadius: BorderRadius.circular(6))
            ],
          );
        }),
      ),
    );
  }

  // -------------------- Line Chart --------------------
  Widget _buildLineChart(Map<int, double> yearlyReturns, double maxY, List<int> lastFiveYears) {
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
                if (index < 0 || index >= lastFiveYears.length) return const SizedBox();
                return Text(lastFiveYears[index].toString(),
                    style: TextStyle(color: widget.primaryText, fontSize: 12));
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
                child: Text("₹${value.toInt()}",
                    style: TextStyle(color: widget.primaryText, fontSize: 12),
                    textAlign: TextAlign.right),
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
                colors: [widget.accent.withOpacity(0.5), widget.accent]),
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                  colors: [widget.accent.withOpacity(0.2), Colors.transparent]),
            ),
          ),
        ],
      ),
    );
  }
}

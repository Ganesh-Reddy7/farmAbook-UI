import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/return_model.dart';
import '../../services/return_service.dart';

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

  Map<int, List<ReturnModel>> returnsByYear = {};
  Map<int, double> yearlyReturns = {};

  @override
  void initState() {
    super.initState();
    _fetchYearlySummary();
    _fetchReturnsForYear(_selectedYear);
  }

  Future<void> _fetchYearlySummary() async {
    final fetched = await ReturnService().getYearlySummary(
      startYear: DateTime.now().year - 4,
      endYear: DateTime.now().year + 1,
    );
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

  @override
  Widget build(BuildContext context) {
    final currentYearReturns = returnsByYear[_selectedYear] ?? [];
    final totalReturn =
    currentYearReturns.fold<double>(0.0, (sum, ret) => sum + ret.amount);
    final lastFiveYears =
    List.generate(5, (i) => DateTime.now().year - i).reversed.toList();
    double maxY = yearlyReturns.values.isNotEmpty
        ? yearlyReturns.values.reduce((a, b) => a > b ? a : b) * 1.2
        : 10000;

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text("Returns",
            style: TextStyle(
                color: widget.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(_isLineChart ? Icons.bar_chart : Icons.show_chart,
                color: widget.accent),
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
              SizedBox(
                height: 250,
                child: _isLineChart
                    ? _buildLineChart(yearlyReturns, maxY, lastFiveYears)
                    : _buildBarChart(yearlyReturns, maxY, lastFiveYears),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Year:",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.primaryText)),
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
              const SizedBox(height: 12),
              Text("Returns in $_selectedYear : ₹${totalReturn.toStringAsFixed(0)}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryText)),
              const SizedBox(height: 20),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: currentYearReturns.length,
                itemBuilder: (context, index) {
                  final ret = currentYearReturns[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          widget.cardGradientStart.withOpacity(0.3),
                          widget.cardGradientEnd.withOpacity(0.2)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: widget.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // LEFT SIDE
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ret.description,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.primaryText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Date: ${ret.date.year}-${ret.date.month.toString().padLeft(2, '0')}-${ret.date.day.toString().padLeft(2, '0')}",
                              style: TextStyle(color: widget.secondaryText),
                            ),
                          ],
                        ),

                        // RIGHT SIDE
                        Text(
                          "₹${ret.amount}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.accent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(
      Map<int, double> yearlyReturns, double maxY, List<int> lastFiveYears) {
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
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= lastFiveYears.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    lastFiveYears[index].toString(),
                    style: TextStyle(color: widget.primaryText, fontSize: 12),
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

  Widget _buildLineChart(
      Map<int, double> yearlyReturns, double maxY, List<int> lastFiveYears) {
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

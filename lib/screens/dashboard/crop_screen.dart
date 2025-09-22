import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crop.dart';
import '../../services/crop_service.dart';
import 'add_entities/add_crop_screen.dart';
import 'crop_details_screen.dart';

class CropsScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const CropsScreen({
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
  _CropsScreenState createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isLineChart = false;

  Map<int, List<Crop>> cropsByYear = {};
  Map<int, double> yearlyCropsValue = {};

  @override
  void initState() {
    super.initState();
    _fetchYearlySummary();
    _fetchCropsForYear(_selectedYear);
  }

  Future<void> _fetchYearlySummary() async {
    final fetched = await CropService().getYearlySummary(
      startYear: DateTime.now().year - 4,
      endYear: DateTime.now().year + 1,
    );

    setState(() {
      yearlyCropsValue = {for (var e in fetched) e['year'] as int : (e['totalValue'] as num).toDouble()};
    });
  }

  Future<void> _fetchCropsForYear(int year) async {
    final fetched = await CropService().getCropsByYear(year);
    setState(() {
      cropsByYear[year] = fetched;
    });
  }

  Future<void> _refreshCurrentYearCrops() async {
    await _fetchCropsForYear(_selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    final currentYearCrops = cropsByYear[_selectedYear] ?? [];
    final totalValue = currentYearCrops.fold<double>(
      0.0,
          (sum, c) => sum + (c.value ?? 0.0),
    );
    final lastFiveYears = List.generate(5, (i) => DateTime.now().year - i).reversed.toList();
    double maxY = yearlyCropsValue.values.isNotEmpty
        ? yearlyCropsValue.values.reduce((a, b) => a > b ? a : b) * 1.2
        : 10000;

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text("Crops",
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
        onRefresh: _refreshCurrentYearCrops,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: _isLineChart
                    ? _buildLineChart(yearlyCropsValue, maxY, lastFiveYears)
                    : _buildBarChart(yearlyCropsValue, maxY, lastFiveYears),
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
                        _fetchCropsForYear(year);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text("Crops in $_selectedYear : ₹${totalValue.toStringAsFixed(0)}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryText)),
              const SizedBox(height: 20),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: currentYearCrops.length,
                itemBuilder: (context, index) {
                  final crop = currentYearCrops[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CropDetailScreen(
                            crop: crop,
                            accent: widget.accent,
                            primaryText: widget.primaryText,
                            secondaryText: widget.secondaryText,
                            scaffoldBg: widget.scaffoldBg,
                            cardGradientStart: widget.cardGradientStart,
                            cardGradientEnd: widget.cardGradientEnd,
                            cardBorder: widget.cardBorder,
                            onUpdate: _refreshCurrentYearCrops,
                          ),
                        ),
                      );
                    },
                    child: Container(
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(crop.name,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: widget.primaryText)),
                              const SizedBox(height: 4),
                              Text("Planted: ${crop.plantedDate}",
                                  style:
                                  TextStyle(color: widget.secondaryText)),
                              Text("Value: ₹${crop.value?.toStringAsFixed(0)}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.accent)),
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
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: widget.accent,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddCropScreen(
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
          if (result == true) _refreshCurrentYearCrops();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBarChart(Map<int, double> yearlyInvestments, double maxY, List<int> lastFiveYears) {
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
                child: Text("₹${value.toInt()}", style: TextStyle(color: widget.primaryText, fontSize: 12), textAlign: TextAlign.right),
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
            barRods: [
              BarChartRodData(toY: value, color: widget.accent, width: 18, borderRadius: BorderRadius.circular(6))
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(Map<int, double> yearlyInvestments, double maxY, List<int> lastFiveYears) {
    // Ensure spots are generated strictly from lastFiveYears
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

// Implement _buildBarChart and _buildLineChart similar to InvestmentsScreen
}

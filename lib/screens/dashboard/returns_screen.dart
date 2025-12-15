import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/return_model.dart';
import '../../services/return_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/barChart.dart';
import '../../widgets/commonLineChart.dart';
import '../../widgets/common_bottom_sheet_selector.dart';
import '../../widgets/sectionTitle.dart';
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
    this.onDataChanged,
    Key? key,
  }) : super(key: key);

  @override
  _ReturnsScreenState createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  int _selectedYear = DateTime.now().year;
  bool _isLineChart = false;
  Map<int, List<ReturnsList>> returnsByYear = {};
  Map<int, double> yearlyReturns = {};
  List<double> chartReturns = [];
  List<String> chartYears = [];

  @override
  void initState() {
    super.initState();
    _fetchYearlySummary();
    _fetchReturnsForYear(_selectedYear);
  }
  Future<void> _fetchYearlySummary() async {
    final fetched = await ReturnService().getYearlySummary(years: 5);
    setState(() {
      chartYears = fetched.map<String>((y) => y.year.toString()).toList();
      chartReturns = fetched.map<double>((y) => y.totalAmount.toDouble()).toList();
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
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    final currentYearReturns = returnsByYear[_selectedYear] ?? [];
    final totalReturns = currentYearReturns.fold<double>(0.0, (sum, ret) => sum + ret.totalReturns);
    final lastFiveYears = List.generate(5, (i) => DateTime.now().year - i).reversed.toList();

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title:SectionTitle(title: "Returns", isDark: isDark , fontSize:18),
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
              const SizedBox(height: 12),
              if(_isLineChart)
                  CommonLineChart(
                  isDark: isDark,
                  labels: chartYears,
                  values: chartReturns,
                  legend1: "Total Returns",
                  lineColor1: Colors.green,
                )
              else
                CommonBarChart(
                  isDark: isDark,
                  chartBg: colors.card,
                  labels: chartYears,
                  values: chartReturns,
                  legend1: "Total Returns",
                  barColor: Colors.green,
                  barWidth: 16,
                ),
              const SizedBox(height: 12),
              Divider(color: colors.divider),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionTitle(title: "Select Year:", isDark: isDark , fontSize:16),
                  GestureDetector(
                    onTap: () async {
                      final selectedYear = await CommonBottomSheetSelector.show<int>(
                        context: context,
                        title: "Select Year",
                        items: lastFiveYears,
                        displayText: (year) => year.toString(),
                        backgroundColor: colors.card,
                        textColor: widget.primaryText,
                        selected: _selectedYear,
                      );
                      if (selectedYear != null) {
                        setState(() => _selectedYear = selectedYear);
                        _fetchReturnsForYear(selectedYear);
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          _selectedYear.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_drop_down,
                          color: widget.primaryText,
                        ),
                      ],
                    ),
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
              SectionTitle(title: "Crop Pie Chart Data", isDark: isDark , fontSize:16),
              const SizedBox(height: 20),
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
                    child:SectionTitle(title: "No pie chart data available", isDark: isDark , fontSize:16),
                  )
                      : PieChart(
                    PieChartData(
                      sections: currentYearReturns.map((ret) {
                        final percentage = totalReturns > 0 ? (ret.totalReturns / totalReturns) * 100 : 0.0;
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
              SectionTitle(title: "Returns in $_selectedYear", isDark: isDark , fontSize:16),
              const SizedBox(height: 20),
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
                    Text("Please add returns to view details.",
                      style: TextStyle(color: widget.secondaryText),
                    ),
                  ],
                ),
              )
                  : Column(children: currentYearReturns.map((ret) => _returnItem(ret)).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: widget.accent,
        heroTag: "add-returns",
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
  Widget _returnItem(ReturnsList ret) {
    final double screenW = MediaQuery.of(context).size.width;

    final double titleSize = screenW < 360 ? 14 : 16;
    final double subTitleSize = screenW < 360 ? 12 : 13;
    final double amountSize = screenW < 360 ? 15 : 17;

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
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),

        /// Updated design --- NO BLUR → SUPER FAST
        decoration: BoxDecoration(
          color: widget.cardGradientStart.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.cardBorder.withOpacity(0.30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT SIDE – Crop Name & Production
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ret.cropName,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Production: ${ret.totalProduction}",
                    style: TextStyle(
                      fontSize: subTitleSize,
                      color: widget.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // RIGHT SIDE – Amount ₹
            Text(
              "₹${ret.totalReturns.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: amountSize,
                fontWeight: FontWeight.bold,
                color: widget.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

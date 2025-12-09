import 'dart:math' hide log;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/SummaryData.dart';
import '../../models/CropData.dart';
import '../../services/reports_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/barChart.dart';
import '../../widgets/commonLineChart.dart';
import '../../widgets/common_bottom_sheet_selector.dart';
import '../../widgets/sectionTitle.dart';

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

class _SummaryScreenState extends State<SummaryScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  List<SummaryData> summaryList = [];
  int _selectedYear = 0;
  bool _showBarChart = true;
  bool _isLoading = true;

  List<CropData> allTimeTopCrops = [];
  List<CropData> allTimeLowCrops = [];
  List<CropData> selectedYearTopCrops = [];
  List<CropData> selectedYearLowCrops = [];

  Map<int, double> yearlyInvestments = {};
  Map<int, double> yearlyReturns = {};

  List<double> chartInvestments = [];
  List<double> chartReturns = [];
  List<String> chartYears = [];

  @override
  void initState() {
    super.initState();
    fetchSummaryAndCrops();
  }

  Future<void> fetchSummaryAndCrops() async {
    setState(() => _isLoading = true);

    try {
      final fetchedSummary = await ReportsService().getYearlyReports(year: 5);
      if (fetchedSummary != null && fetchedSummary.isNotEmpty) {
        summaryList = fetchedSummary;
        _selectedYear = fetchedSummary.last.year;
        yearlyInvestments.clear();
        yearlyReturns.clear();
        chartYears = summaryList.map<String>((y) => y.year.toString()).toList();
        chartInvestments = summaryList.map<double>((y) => y.totalInvestment.toDouble()).toList();
        chartReturns = summaryList.map<double>((y) => y.totalReturns.toDouble()).toList();
        for (var e in summaryList) {
          yearlyInvestments[e.year] = e.totalInvestment;
          yearlyReturns[e.year] = e.totalReturns;
        }
        // Fetch all-time crops
        final allTimeCrops = await ReportsService().getCropsDistributionData(year: 0);
        allTimeTopCrops = allTimeCrops['topCrops'] ?? [];
        allTimeLowCrops = allTimeCrops['lowCrops'] ?? [];

        // Fetch selected year crops
        final yearCrops = await ReportsService().getCropsDistributionData(year: _selectedYear);
        selectedYearTopCrops = yearCrops['topCrops'] ?? [];
        selectedYearLowCrops = yearCrops['lowCrops'] ?? [];
      }
      else {
        summaryList = [];
      }
    } catch (e) {
      print("Error fetching summary/crops: $e");
      summaryList = [];
    }

    setState(() => _isLoading = false);
  }
  double safeMaxY(double value) => value > 0 ? value * 1.2 : 1000;
  double get maxY {
    if (yearlyInvestments.isEmpty && yearlyReturns.isEmpty) return 1000;
    final maxInv = yearlyInvestments.values.isEmpty ? 0 : yearlyInvestments.values.reduce((a, b) => a > b ? a : b);
    final maxRet = yearlyReturns.values.isEmpty ? 0 : yearlyReturns.values.reduce((a, b) => a > b ? a : b);
    return safeMaxY((max(maxInv, maxRet)) as double);
  }

  double getReservedYTitleSize(double maxY, TextStyle style) {
    final text = "₹${maxY.toInt()}";
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width + 8;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: SectionTitle(title: "Summary (Investment & Returns)", isDark: isDark , fontSize:16),
        actions: [
          IconButton(
            icon: Icon(
              _showBarChart ? Icons.show_chart : Icons.bar_chart,
              color: widget.accent,
            ),
            onPressed: () => setState(() => _showBarChart = !_showBarChart),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchSummaryAndCrops,
        child: _isLoading
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Center(child: CircularProgressIndicator()),
          ],
        )
            : summaryList.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 150),
            Center(
              child: Text(
                "No summary data available",
                style: TextStyle(color: widget.secondaryText, fontSize: 16),
              ),
            ),
          ],
        )
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              if(_showBarChart)
                CommonBarChart(
                  isDark: isDark,
                  chartBg: colors.card,
                  labels: chartYears,
                  values: chartInvestments,
                  values2: chartReturns,
                  legend1: "Total Investment",
                  legend2: "Total Returns",
                  barColor2: Colors.green,
                  barColor: Colors.orange,
                  barWidth: 16,
                )
              else
                CommonLineChart(
                  isDark: isDark,
                  labels: chartYears,
                  values: chartInvestments,
                  values2: chartReturns,
                  legend1: "Total Investment",
                  legend2: "Total Returns",
                  lineColor1: widget.accent,
                  lineColor2: Colors.orangeAccent,
                ),
              const SizedBox(height: 12),
              Divider(color: colors.divider),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionTitle(title: "Select Year :", isDark: isDark , fontSize:16),
                  GestureDetector(
                    onTap: () async {
                      final selectedYear = await CommonBottomSheetSelector.show<int>(
                        context: context,
                        title: "Select Year",
                        items: summaryList.map((e) => e.year).toList(),
                        displayText: (year) => year.toString(),
                        backgroundColor: colors.card,
                        textColor: widget.primaryText,
                        selected: _selectedYear,
                      );
                      if (selectedYear != null) {
                        setState(() => _selectedYear = selectedYear);
                        final yearCrops = await ReportsService().getCropsDistributionData(year: _selectedYear);
                        setState(() {
                          selectedYearTopCrops = yearCrops['topCrops'] ?? [];
                          selectedYearLowCrops = yearCrops['lowCrops'] ?? [];
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          _selectedYear.toString(),
                          style: TextStyle(color: widget.primaryText, fontSize: 16),
                        ),
                        Icon(Icons.arrow_drop_down , color: widget.primaryText),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Pie Chart inside container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: SizedBox(
                  height: 220,
                  child: _buildInvestmentReturnPieChart(),
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                _selectedYear,
                summaryList.firstWhere((e) => e.year == _selectedYear),
              ),
              const SizedBox(height: 24),
              // All-Time Crops
              SectionTitle(title: "All-Time Top Performing Crops", isDark: isDark , fontSize:16),
              const SizedBox(height: 8),
              _buildCropCards(allTimeTopCrops),
              const SizedBox(height: 16),
              SectionTitle(title: "All-Time Low Performing Crops", isDark: isDark , fontSize:16),
              const SizedBox(height: 8),
              _buildCropCards(allTimeLowCrops),
              const SizedBox(height: 24),
              // Selected Year Crops
              SectionTitle(title: "Top Performing Crops in $_selectedYear", isDark: isDark , fontSize:16),
              const SizedBox(height: 8),
              _buildCropCards(selectedYearTopCrops),
              const SizedBox(height: 16),
              SectionTitle(title: "Low Performing Crops in $_selectedYear", isDark: isDark , fontSize:16),
              const SizedBox(height: 8),
              _buildCropCards(selectedYearLowCrops),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropCards(List<CropData> crops) {
    if (crops.isEmpty) {
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 40, color: widget.accent),
            const SizedBox(height: 12),
            Text(
              "No crops data available",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.secondaryText),
            ),
            const SizedBox(height: 6),
            Text(
              "Please add crops to view details.",
              style: TextStyle(color: widget.secondaryText),
            ),
          ],
        ),
      );
    }

    return Column(
      children: crops.map((crop) {
        return Container(
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
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5)),
            ],
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
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crop.cropName,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryText),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 16, color: widget.primaryText),
                              const SizedBox(width: 4),
                              Text(
                                "₹${crop.totalInvestment.toStringAsFixed(0)}",
                                style: TextStyle(color: widget.primaryText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.attach_money,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                "₹${crop.totalReturns.toStringAsFixed(0)}",
                                style: TextStyle(color: widget.primaryText),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // -------------------- Right Stats --------------------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Profit: ₹${crop.profit.toStringAsFixed(0)}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: widget.accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Yield: ${crop.yieldValue.toStringAsFixed(2)}",
                            style: TextStyle(color: Colors.green[800]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  double getLeftReservedSize(double maxValue, TextStyle style) {
    final text = "₹${maxValue.toInt()}"; // largest Y label
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width + 8; // some padding
  }

  Widget _buildInvestmentReturnPieChart() {
    if (summaryList.isEmpty) {
      return Center(child: Text("No pie chart data", style: TextStyle(color: widget.secondaryText)));
    }

    final selectedData = summaryList.firstWhere((e) => e.year == _selectedYear);

    if (selectedData.totalInvestment == 0 && selectedData.totalReturns == 0) {
      return Center(child: Text("No pie chart data", style: TextStyle(color: widget.secondaryText)));
    }

    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: selectedData.totalInvestment,
            color: widget.accent,
            title: selectedData.totalInvestment > 0 ? "₹${selectedData.totalInvestment.toInt()}" : "",
            radius: 60,
          ),
          PieChartSectionData(
            value: selectedData.totalReturns,
            color: Colors.orangeAccent,
            title: selectedData.totalReturns > 0 ? "₹${selectedData.totalReturns.toInt()}" : "",
            radius: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int year, SummaryData summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // -------------------- Investment --------------------
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: widget.accent, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                "Investment",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.primaryText),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${summary.totalInvestment.toStringAsFixed(0)}",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText),
              ),
            ],
          ),

          // -------------------- Returns --------------------
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.attach_money, color: Colors.green, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                "Returns",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.primaryText),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${summary.totalReturns.toStringAsFixed(0)}",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

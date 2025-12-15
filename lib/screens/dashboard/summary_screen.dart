import 'dart:math' hide log;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/SummaryData.dart';
import '../../models/CropData.dart';
import '../../services/reports_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/CommonRoiDonutChart.dart';
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

class _SummaryScreenState extends State<SummaryScreen>
    with AutomaticKeepAliveClientMixin {
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

  /// Memoized summary for selected year to avoid doing firstWhere in build
  SummaryData? _selectedSummary;

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

        chartYears =
            summaryList.map<String>((y) => y.year.toString()).toList();
        chartInvestments =
            summaryList.map<double>((y) => y.totalInvestment.toDouble()).toList();
        chartReturns =
            summaryList.map<double>((y) => y.totalReturns.toDouble()).toList();

        for (var e in summaryList) {
          yearlyInvestments[e.year] = e.totalInvestment;
          yearlyReturns[e.year] = e.totalReturns;
        }

        _selectedSummary =
            summaryList.firstWhere((e) => e.year == _selectedYear);

        // Fetch all-time crops
        final allTimeCrops =
        await ReportsService().getCropsDistributionData(year: 0);
        allTimeTopCrops = allTimeCrops['topCrops'] ?? [];
        allTimeLowCrops = allTimeCrops['lowCrops'] ?? [];

        // Fetch selected year crops
        final yearCrops = await ReportsService()
            .getCropsDistributionData(year: _selectedYear);
        selectedYearTopCrops = yearCrops['topCrops'] ?? [];
        selectedYearLowCrops = yearCrops['lowCrops'] ?? [];
      } else {
        summaryList = [];
        _selectedSummary = null;
      }
    } catch (e) {
      print("Error fetching summary/crops: $e");
      summaryList = [];
      _selectedSummary = null;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: SectionTitle(
          title: "Summary (Investment & Returns)",
          isDark: isDark,
          fontSize: 16,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showBarChart ? Icons.show_chart : Icons.bar_chart,
              color: widget.accent,
            ),
            onPressed: () {
              setState(() {
                _showBarChart = !_showBarChart;
              });
            },
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
            const SizedBox(height: 150),
            Center(
              child: Text(
                "No summary data available",
                style: TextStyle(
                  color: widget.secondaryText,
                  fontSize: 16,
                ),
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

              /// Chart Section with repaint isolation
              RepaintBoundary(
                child: _buildChartSection(isDark, colors),
              ),

              const SizedBox(height: 12),
              Divider(color: colors.divider),
              const SizedBox(height: 12),

              /// Year selector
              _buildYearSelector(isDark, colors),

              const SizedBox(height: 16),

              /// Pie chart section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: SizedBox(
                  height: 220,
                  child: RepaintBoundary(
                    child: LogRoiDonut(
                      investment: _selectedSummary!.totalInvestment.toDouble(),
                      returns: _selectedSummary!.totalReturns.toDouble(),
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              /// Summary card (investment & returns)
              if (_selectedSummary != null)
                _buildSummaryCard(_selectedYear, _selectedSummary!),

              const SizedBox(height: 24),

              /// All-time crops
              SectionTitle(
                title: "All-Time Top Performing Crops",
                isDark: isDark,
                fontSize: 16,
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: _buildCropCards(allTimeTopCrops),
              ),
              const SizedBox(height: 16),
              SectionTitle(
                title: "All-Time Low Performing Crops",
                isDark: isDark,
                fontSize: 16,
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: _buildCropCards(allTimeLowCrops),
              ),

              const SizedBox(height: 24),

              /// Selected year crops
              SectionTitle(
                title: "Top Performing Crops in $_selectedYear",
                isDark: isDark,
                fontSize: 16,
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: _buildCropCards(selectedYearTopCrops),
              ),
              const SizedBox(height: 16),
              SectionTitle(
                title: "Low Performing Crops in $_selectedYear",
                isDark: isDark,
                fontSize: 16,
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: _buildCropCards(selectedYearLowCrops),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chart section (bar / line toggle)
  Widget _buildChartSection(bool isDark, AppColors colors) {
    if (chartYears.isEmpty) {
      return Center(
        child: Text(
          "No chart data available",
          style: TextStyle(color: widget.secondaryText),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _showBarChart
          ? CommonBarChart(
        key: const ValueKey('bar_chart'),
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
        isLoading: _isLoading,
      )
          : CommonLineChart(
        key: const ValueKey('line_chart'),
        isDark: isDark,
        labels: chartYears,
        values: chartInvestments,
        values2: chartReturns,
        legend1: "Total Investment",
        legend2: "Total Returns",
        lineColor1: Colors.orange,
        lineColor2: Colors.green,
      ),
    );
  }

  /// Year selector row
  Widget _buildYearSelector(bool isDark, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SectionTitle(
          title: "Select Year :",
          isDark: isDark,
          fontSize: 16,
        ),
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
            if (selectedYear != null && selectedYear != _selectedYear) {
              _onYearChanged(selectedYear);
            }
          },
          child: Row(
            children: [
              Text(
                _selectedYear.toString(),
                style: TextStyle(
                  color: widget.primaryText,
                  fontSize: 16,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: widget.primaryText),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onYearChanged(int year) async {
    setState(() {
      _selectedYear = year;
      _selectedSummary =
          summaryList.firstWhere((e) => e.year == _selectedYear);
    });

    final yearCrops =
    await ReportsService().getCropsDistributionData(year: _selectedYear);

    if (!mounted) return;

    setState(() {
      selectedYearTopCrops = yearCrops['topCrops'] ?? [];
      selectedYearLowCrops = yearCrops['lowCrops'] ?? [];
    });
  }

  Widget _buildCropCards(List<CropData> crops) {
    if (crops.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 40, color: widget.accent),
            const SizedBox(height: 12),
            Text(
              "No crops data available",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.secondaryText,
              ),
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
      children: List.generate(crops.length, (index) {
        final crop = crops[index];

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: widget.cardGradientStart.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.cardBorder.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Crop Name + Profit Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    crop.cropName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryText,
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (crop.profit >= 0
                          ? Colors.green
                          : Colors.red)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "₹${crop.profit.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: crop.profit >= 0
                            ? Colors.green[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// Investment & Returns row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statRow(Icons.account_balance_wallet_outlined,
                      "Investment", crop.totalInvestment),
                  _statRow(Icons.attach_money, "Returns", crop.totalReturns),
                ],
              ),

              const SizedBox(height: 8),

              /// Yield row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.trending_up,
                      size: 18, color: Colors.green[700]),
                  const SizedBox(width: 6),
                  Text(
                    "Yield: ${crop.yieldValue.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: widget.primaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _statRow(IconData icon, String label, num value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: widget.primaryText),
        const SizedBox(width: 4),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            color: widget.secondaryText,
          ),
        ),
        Text(
          "₹${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: widget.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentReturnPieChart() {
    if (summaryList.isEmpty || _selectedSummary == null) {
      return Center(
        child: Text(
          "No pie chart data",
          style: TextStyle(color: widget.secondaryText),
        ),
      );
    }

    final selectedData = _selectedSummary!;

    if (selectedData.totalInvestment == 0 &&
        selectedData.totalReturns == 0) {
      return Center(
        child: Text(
          "No pie chart data",
          style: TextStyle(color: widget.secondaryText),
        ),
      );
    }

    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: selectedData.totalInvestment,
            color: widget.accent,
            title: selectedData.totalInvestment > 0
                ? "₹${selectedData.totalInvestment.toInt()}"
                : "",
            radius: 60,
          ),
          PieChartSectionData(
            value: selectedData.totalReturns,
            color: Colors.orangeAccent,
            title: selectedData.totalReturns > 0
                ? "₹${selectedData.totalReturns.toInt()}"
                : "",
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
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Investment
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Investment",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${summary.totalInvestment.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryText,
                ),
              ),
            ],
          ),

          // Returns
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.currency_rupee_outlined,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Returns",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${summary.totalReturns.toStringAsFixed(0)}",
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
}

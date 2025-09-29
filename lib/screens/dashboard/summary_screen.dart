import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/SummaryData.dart';
import '../../models/CropData.dart';
import '../../services/reports_service.dart';

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
  List<SummaryData> summaryList = [];
  int _selectedYear = 0;
  bool _showBarChart = true;
  bool _isLoading = true;

  List<CropData> allTimeTopCrops = [];
  List<CropData> allTimeLowCrops = [];
  List<CropData> selectedYearTopCrops = [];
  List<CropData> selectedYearLowCrops = [];

  @override
  void initState() {
    super.initState();
    fetchSummaryAndCrops();
  }

  Future<void> fetchSummaryAndCrops() async {
    setState(() => _isLoading = true);

    try {
      // Fetch summary data
      final fetchedSummary = await ReportsService().getYearlyReports(year: 5);

      if (fetchedSummary != null && fetchedSummary.isNotEmpty) {
        summaryList = fetchedSummary;
        _selectedYear = fetchedSummary.last.year;

        // Fetch all-time crops (year = 0)
        final allTimeCrops = await ReportsService().getCropsDistributionData(year: 0);
        allTimeTopCrops = allTimeCrops['topCrops'] ?? [];
        allTimeLowCrops = allTimeCrops['lowCrops'] ?? [];

        // Fetch selected year crops
        final yearCrops = await ReportsService().getCropsDistributionData(year: _selectedYear);
        selectedYearTopCrops = yearCrops['topCrops'] ?? [];
        selectedYearLowCrops = yearCrops['lowCrops'] ?? [];
      } else {
        summaryList = [];
      }
    } catch (e) {
      print("Error fetching summary/crops: $e");
      summaryList = [];
    }

    setState(() => _isLoading = false);
  }

  double get maxY {
    if (summaryList.isEmpty) return 0;
    final values = [
      ...summaryList.map((e) => e.totalInvestment),
      ...summaryList.map((e) => e.totalReturns),
    ];
    return (values.reduce((a, b) => a > b ? a : b)) * 1.2;
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
    final yLabelStyle = TextStyle(color: widget.primaryText, fontSize: 12);
    final reservedSize = getReservedYTitleSize(maxY, yLabelStyle);

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chart container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: SizedBox(
                  height: 250,
                  child: _showBarChart
                      ? _buildNeonBarChart(reservedSize, yLabelStyle)
                      : _buildNeonLineChart(reservedSize, yLabelStyle),
                ),
              ),

              const SizedBox(height: 16),

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
                    items: summaryList.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.year,
                        child: Text(
                          e.year.toString(),
                          style: TextStyle(color: widget.primaryText),
                        ),
                      );
                    }).toList(),
                    onChanged: (year) async {
                      setState(() => _selectedYear = year!);
                      final yearCrops = await ReportsService()
                          .getCropsDistributionData(year: _selectedYear);
                      setState(() {
                        selectedYearTopCrops = yearCrops['topCrops'] ?? [];
                        selectedYearLowCrops = yearCrops['lowCrops'] ?? [];
                      });
                    },
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
              Text(
                "All-Time Top Performing Crops",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText),
              ),
              const SizedBox(height: 8),
              _buildCropCards(allTimeTopCrops),

              const SizedBox(height: 16),

              Text(
                "All-Time Low Performing Crops",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText),
              ),
              const SizedBox(height: 8),
              _buildCropCards(allTimeLowCrops),

              const SizedBox(height: 24),

              // Selected Year Crops
              Text(
                "Top Performing Crops in $_selectedYear",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText),
              ),
              const SizedBox(height: 8),
              _buildCropCards(selectedYearTopCrops),

              const SizedBox(height: 16),

              Text(
                "Low Performing Crops in $_selectedYear",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText),
              ),
              const SizedBox(height: 8),
              _buildCropCards(selectedYearLowCrops),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropCards(List<CropData> crops) {
    // -------------------- No Data Card --------------------
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

    // -------------------- Data Cards --------------------
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
                    // -------------------- Left Info --------------------
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

  Widget _buildNeonLineChart(double reservedSize, TextStyle yLabelStyle) {
    if (summaryList.isEmpty)
      return Center(child: Text("No chart data", style: TextStyle(color: widget.secondaryText)));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (summaryList.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= summaryList.length) return Container();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Text(
                      summaryList[value.toInt()].year.toString(),
                      style: yLabelStyle,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: reservedSize,
              getTitlesWidget: (value, meta) =>
                  Text("₹${value.toInt()}", style: yLabelStyle),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: summaryList
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.totalInvestment))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(colors: [widget.accent, Colors.greenAccent]),
            barWidth: 3,
          ),
          LineChartBarData(
            spots: summaryList
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.totalReturns))
                .toList(),
            isCurved: true,
            gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
            barWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNeonBarChart(double reservedSize, TextStyle yLabelStyle) {
    if (summaryList.isEmpty)
      return Center(child: Text("No chart data", style: TextStyle(color: widget.secondaryText)));
    final count = summaryList.length;
    final spacing = count > 5 ? 6.0 : 16.0;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxY,
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= count) return Container();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Transform.rotate(
                    angle: count > 5 ? 0.4 : 0,
                    child: Text(
                      summaryList[value.toInt()].year.toString(),
                      style: yLabelStyle,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: reservedSize,
              getTitlesWidget: (value, meta) =>
                  Text("₹${value.toInt()}", style: yLabelStyle),
            ),
          ),
        ),
        barGroups: summaryList.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.totalInvestment,
                gradient: LinearGradient(colors: [widget.accent, Colors.greenAccent]),
                width: 14,
              ),
              BarChartRodData(
                toY: e.value.totalReturns,
                gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
                width: 14,
              ),
            ],
            barsSpace: spacing,
          );
        }).toList(),
      ),
    );
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

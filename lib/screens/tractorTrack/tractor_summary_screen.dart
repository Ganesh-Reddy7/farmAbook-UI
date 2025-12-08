import 'package:flutter/material.dart';
import '../../services/TractorService/tractor_service.dart';
import '../../widgets/NegativeBarChart.dart';
import '../../widgets/barChart.dart';
import '../../widgets/sectionTitle.dart';

class TractorSummaryScreen extends StatefulWidget {
  const TractorSummaryScreen({Key? key}) : super(key: key);
  @override
  State<TractorSummaryScreen> createState() => _TractorSummaryScreenState();
}

class _TractorSummaryScreenState extends State<TractorSummaryScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  List<double> chartValuesExpense = [];
  List<double> chartValuesReturns = [];
  List<double> chartValuesFuel = [];
  List<double> chartValuesArea = [];
  List<double> yearlyProfit = [];
  List<int> chartYears = [];
  bool isLoading = false;

  final tractorService = TractorService();

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async{
    setState(() => isLoading = true);
    try {
      int currentYear = DateTime.now().year;
      int startYear = currentYear - 5;
      final yearlyList = await tractorService.getYearlySummary(
        startYear: startYear,
        endYear: currentYear,
      );
      chartYears = yearlyList.map<int>((y) => y["year"] as int).toList();
      chartValuesExpense = yearlyList.map<double>((y) => (y["totalExpenses"] as num).toDouble()).toList();
      chartValuesReturns = yearlyList.map<double>((y) => (y["totalReturns"] as num).toDouble()).toList();
      chartValuesFuel = yearlyList.map<double>((y) => (y["fuelLitres"] as num).toDouble()).toList();
      chartValuesArea = yearlyList.map<double>((y) => (y["acresWorked"] as num).toDouble()).toList();
      yearlyProfit = yearlyList.map<double>((y) => (y["totalProfit"] as num).toDouble()).toList();
    } catch (e) {
      debugPrint("Error loading chart data: $e");
    }

    setState(() => isLoading = false);

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = Theme.of(context).brightness != Brightness.dark
        ? Colors.white
        : Colors.black87;
    final isDark = theme.brightness != Brightness.dark;
    final colors = _AppColors(isDark);

    if (isLoading) {
      return Scaffold(
        backgroundColor: colors.card,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.card,
      body: SafeArea(
        child: RefreshIndicator(
            color: colors.card,
            strokeWidth: 2.5,
            onRefresh: () async {
              _loadSummaryData();
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(title: "Yearly Summary (₹)", isDark: isDark),
                  const SizedBox(height: 12),
                  CommonBarChart(
                    isDark: isDark,
                    chartBg: colors.card,
                    labels: chartYears.map((e) => e.toString()).toList(),
                    values: chartValuesReturns,
                    values2: chartValuesExpense,
                    legend1: "Total Returns",
                    legend2: "Total Expenses",
                    barColor2: Colors.blue,
                    barColor: Colors.green,
                    barWidth: 8,
                  ),
                  const SizedBox(height: 12),
                  SectionTitle(title: "Area(Acre) Vs Fuel(L)", isDark: isDark),
                  const SizedBox(height: 12),
                  CommonBarChart(
                    isDark: isDark,
                    chartBg: colors.card,
                    labels: chartYears.map((e) => e.toString()).toList(),
                    values: chartValuesArea,
                    values2: chartValuesFuel,
                    legend1: "Area",
                    legend2: "Fuel",
                    barColor: Colors.brown,
                    barColor2: Colors.orangeAccent,
                    barWidth: 8,
                  ),
                  const SizedBox(height: 12),
                  SectionTitle(title: "Yearly Profit (₹)", isDark: isDark),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: SingleMetricChart(
                      years: chartYears.map((e) => e.toString()).toList(),
                      values: yearlyProfit,
                      isDark: isDark,
                    ),
                  )
                ],
              ),
            ),
        ),
      ),
    );
  }
}

class _AppColors {
  final Color background;
  final Color card;
  final Color text;
  final Color divider;

  _AppColors(bool isDark)
      : background = isDark ? const Color(0xFF121212) : Colors.white,
        card = isDark ? const Color(0xFF081712) : Colors.grey.shade100,
        text = isDark ? Colors.white : Colors.black87,
        divider = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
}
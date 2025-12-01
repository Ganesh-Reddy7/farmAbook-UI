import 'package:farmabook/utils/formatIndianNumber.dart';
import 'package:farmabook/widgets/barChart.dart';
import 'package:farmabook/widgets/sectionTitle.dart';
import 'package:farmabook/widgets/tractorInfoCard.dart';
import 'package:flutter/material.dart';
import '../../services/TractorService/tractor_service.dart';
import 'add_entities/add_return.dart';
import 'details_screen/client_list.dart';

class TractorReturnsScreen extends StatefulWidget {
  const TractorReturnsScreen({Key? key}) : super(key: key);

  @override
  State<TractorReturnsScreen> createState() => _TractorReturnsScreenState();
}

class _TractorReturnsScreenState extends State<TractorReturnsScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  List<Map<String, dynamic>> tractors = [];
  bool isLoading = false;
  double totalReturns = 0;
  double receivedAmount = 0;
  double balanceAmount = 0;
  double totalAreaWorked = 0;
  int currentYear = 0;
  List<double> chartValues = [];
  List<int> chartYears = [];
  List<double> monthlyChartValues = [];
  List<String> monthlyChartLabels = [];
  List<double> monthlyChartValuesReceived = [];
  List<double> monthlyReturns = List.filled(12, 0);
  final tractorService = TractorService();

  @override
  void initState() {
    super.initState();
    _loadReturnsData();
  }

  void _loadReturnsData() {
    _loadChartData();
    _loadMonthlyChartData();

  }

  Future<void> _loadChartData() async {
    setState(() => isLoading = true);
    try {
      int currentYear = DateTime.now().year;
      int startYear = currentYear - 5;
      final yearlyList = await tractorService.getYearlyReturns(
        startYear: startYear,
        endYear: currentYear,
      );
      chartYears = yearlyList.map<int>((y) => y["year"] as int).toList();
      chartValues =
          yearlyList.map<double>((y) => (y["totalYearAmount"] as num).toDouble()).toList();
    } catch (e) {
      debugPrint("Error loading chart data: $e");
    }

    setState(() => isLoading = false);
  }
  Future<void> _loadMonthlyChartData() async {
    try {
      int year = DateTime.now().year;
      final data = await tractorService.getYearlyReturns(
        startYear: year,
        endYear: year,
        isSummary: true
      );
      if (data.isNotEmpty) {
        final months = data[0]["monthlyActivities"] as List<dynamic>;
        monthlyChartLabels = monthlyChartLabels = months.map((m) {
          final s = m["month"].toString();
          return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
        }).toList();
        monthlyChartValues = months.map<double>((m) => (m["total"] as num).toDouble()).toList();
        monthlyChartValuesReceived = months.map<double>((m) => (m["received"] as num).toDouble()).toList();
        totalReturns = data[0]["totalYearAmount"];
        totalAreaWorked = data[0]["totalYearAcres"];
        receivedAmount = data[0]["totalYearReceived"];
        balanceAmount = data[0]["totalYearRemaining"];
        currentYear = year;
      }
    } catch (e) {
      debugPrint("Error loading monthly chart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final colors = _AppColors(isDark);

    if (isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: scaffoldBg,
          strokeWidth: 2.5,
          onRefresh: () async {
            _loadReturnsData();
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: "Yearly Returns (₹)", isDark: isDark),
              const SizedBox(height: 12),
              CommonBarChart(
                isDark: isDark,
                chartBg: colors.card,
                labels: chartYears.map((e) => e.toString()).toList(),
                values: chartValues,
                legend1: "Total Returns",
                barColor: Colors.blueAccent,
                barWidth: 20,
              ),
              Divider(color: colors.divider),
              const SizedBox(height: 12),
              SectionTitle(title: "Monthly Returns (₹)", isDark: isDark),
              const SizedBox(height: 12),

              CommonBarChart(
                isDark: isDark,
                chartBg: colors.card,
                labels: monthlyChartLabels,
                values: monthlyChartValuesReceived,
                values2: monthlyChartValues,
                legend1: "Total Amount",
                legend2: "Amount Received",
                barColor2: Colors.blue,
                barColor: Colors.green,
                barWidth: 8,
              ),
              const SizedBox(height: 16),
              Divider(color: colors.divider),
              SectionTitle(title: "Returns Summary , $currentYear", isDark: isDark),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InfoCard(
                          icon: Icons.account_balance,
                          iconColor: Colors.blueAccent,
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          label: "Total",
                          value: NumberUtils.formatIndianNumber(totalReturns),
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.currency_rupee,
                          iconColor: Colors.orange,
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          label: "Received",
                          value: NumberUtils.formatIndianNumber(receivedAmount),
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.balance,
                          iconColor: Colors.redAccent,
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                          label: "Balance",
                          value: NumberUtils.formatIndianNumber(balanceAmount),
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.landscape,
                          iconColor: Colors.green,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          label: "Acres",
                          value: NumberUtils.formatIndianNumber(totalAreaWorked),
                          textColor: colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(title: "Returns Details (Current Year)", isDark: isDark),
              const SizedBox(height: 12),
            ],
          ),
        ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "viewClients",
            backgroundColor: Colors.blueGrey,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewClientsPage()));
            },
            child: const Icon(Icons.people, color: Colors.white),
          ),
          const SizedBox(height: 12),

          FloatingActionButton(
            heroTag: "addReturn",
            backgroundColor: Colors.green,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddReturnPage()),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
// -------------------- Theme Colors --------------------
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

import 'package:flutter/material.dart';
import '../../utils/slide_route.dart';
import '../../widgets/NegativeBarChart.dart';
import '../../widgets/barChart.dart';
import '../../widgets/sectionTitle.dart';
import 'add_entities/add_tractor.dart';
import 'details_screen/tractor_details_page.dart';
import '../../services/TractorService/tractor_service.dart';

class TractorDetailsScreen extends StatefulWidget {
  const TractorDetailsScreen({super.key});
  @override
  State<TractorDetailsScreen> createState() => _TractorDetailsScreenState();
}
class _TractorDetailsScreenState extends State<TractorDetailsScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  final TractorService _tractorService = TractorService();
  List<Map<String, dynamic>> tractors = [];
  List<String> monthlyChartLabels = [];
  List<double> monthlyReturns = [];
  List<double> monthlyExpenses = [];
  List<double> monthlyAcresWorked = [];
  List<double> monthlyFuelConsumed= [];
  List<double> monthlyProfit = [];


  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTractors();
    _loadMonthlyChartData();
  }

  Future<void> _loadTractors() async {
    final data = await _tractorService.fetchTractors();
    setState(() {
      tractors = data;
      isLoading = false;
    });
  }

  Future<void> _loadMonthlyChartData() async {
    try {
      int year = DateTime.now().year;
      final data = await _tractorService.getMonthlyTractorStats(
          year: year,
      );
      if (data.isNotEmpty) {
        monthlyChartLabels = monthlyChartLabels = data.map((m) {
          final s = m["month"].toString();
          return  s;
        }).toList();
        monthlyReturns = data.map<double>((m) => (m["returnsAmount"] as num).toDouble()).toList();
        monthlyExpenses = data.map<double>((m) => (m["expenseAmount"] as num).toDouble()).toList();
        monthlyAcresWorked = data.map<double>((m) => (m["acresWorked"] as num).toDouble()).toList();;
        monthlyFuelConsumed = data.map<double>((m) => (m["fuelLitres"] as num).toDouble()).toList();;
        monthlyProfit = data.map<double>((m) => (m["totalProfit"] as num).toDouble()).toList();;
      }
    } catch (e) {
      debugPrint("Error loading monthly chart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required because of AutomaticKeepAliveClientMixin

    final isDark = Theme.of(context).brightness != Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final colors = _AppColorsMain(isDark);

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
          color: Colors.green,
          strokeWidth: 2.5,
          onRefresh: _loadTractors,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    SectionTitle(title: "Monthly Returns and Expenses (₹)", isDark: isDark),
                    const SizedBox(height: 16),
                    CommonBarChart(
                      isDark: isDark,
                      chartBg: colors.card,
                      labels: monthlyChartLabels,
                      values: monthlyReturns,
                      values2: monthlyExpenses,
                      legend1: "Returns",
                      legend2: "Expenses",
                      barColor2: Colors.blue,
                      barColor: Colors.green,
                      barWidth: 8,
                    ),
                    const SizedBox(height: 16),
                    SectionTitle(title: "Monthly Fuel and Acres", isDark: isDark),
                    const SizedBox(height: 16),
                    CommonBarChart(
                      isDark: isDark,
                      chartBg: colors.card,
                      labels: monthlyChartLabels,
                      values: monthlyFuelConsumed,
                      values2: monthlyAcresWorked,
                      legend1: "Fuel",
                      legend2: "Acres Worked",
                      barColor: Colors.limeAccent,
                      barColor2: Colors.brown,
                      barWidth: 8,
                    ),
                    const SizedBox(height: 16),
                    SectionTitle(title: "Monthly Profit (₹)", isDark: isDark),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: SingleMetricChart(
                        years: monthlyChartLabels,
                        values: monthlyProfit,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _TractorListSection(
                      tractors: tractors,
                      colors: _AppColors(isDark),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add-tractor",
        backgroundColor: Colors.green.shade700,
        onPressed: () => _navigateToAddTractor(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  void _navigateToAddTractor(BuildContext context) {
    Navigator.of(context).push(
      SlideFromRightRoute(
        page: const AddTractorPage(),
      ),
    );
  }
}

class _TractorListSection extends StatelessWidget {
  final List<Map<String, dynamic>> tractors;
  final _AppColors colors;

  const _TractorListSection({required this.tractors, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Tractors",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 12),
        if (tractors.isEmpty)
          Center(
            child: Text(
              "No tractors added yet.",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          )
        else
          ...tractors.map((tractor) => _TractorTile(
            tractor: tractor,
            colors: colors,
            onTap: () => _navigateToTractorDetails(context, tractor),
          )),
      ],
    );
  }

  void _navigateToTractorDetails(BuildContext context, Map<String, dynamic> tractor,) {
    Navigator.of(context).push(
      SlideFromRightRoute(
        page: TractorDetailPage(tractor: tractor),
      ),
    );
  }
}

class _TractorTile extends StatelessWidget {
  final Map<String, dynamic> tractor;
  final _AppColors colors;
  final VoidCallback onTap;

  const _TractorTile({
    required this.tractor,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit =
        (tractor['totalReturns'] ?? 0) > (tractor['totalExpenses'] ?? 0);
    final profitColor = isProfit ? Colors.green : Colors.red;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.transparent,
            ], // ✅ No solid background
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.agriculture, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${tractor['model'] ?? 'Unknown'} (${tractor['serialNumber'] ?? '-'})",
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Expenses ₹${tractor['totalExpenses'] ?? 0} | Returns ₹${tractor['totalReturns'] ?? 0}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Fuel ${tractor['totalFuelLitres'] ?? 0}L | Area ${tractor['totalAreaWorked'] ?? 0}ac",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Net ₹${tractor['netProfit'] ?? 0}",
                    style: TextStyle(
                      color: profitColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
class _AppColors {
  final Color text;
  final bool isDark;

  _AppColors(this.isDark)
      : text = isDark ? Colors.white : Colors.black87;
}

class _AppColorsMain {
  final Color background;
  final Color card;
  final Color text;
  final Color divider;

  _AppColorsMain(bool isDark)
      : background = isDark ? const Color(0xFF121212) : Colors.white,
        card = isDark ? const Color(0xFF081712) : Colors.grey.shade100,
        text = isDark ? Colors.white : Colors.black87,
        divider = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
}

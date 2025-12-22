import 'package:flutter/material.dart';

import '../../../services/TractorService/tractor_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/NegativeBarChart.dart';
import '../../../widgets/barChart.dart';
import '../../../widgets/sectionTitle.dart';

class TractorDetailPage extends StatefulWidget {
  final Map<String, dynamic> tractor;
  const TractorDetailPage({super.key, required this.tractor});

  @override
  State<TractorDetailPage> createState() => _TractorDetailPageState();
}

class _TractorDetailPageState extends State<TractorDetailPage> {
  final TractorService _tractorService = TractorService();
  late final Map<String, dynamic> tractor = widget.tractor;
  List<String> monthlyChartLabels = [];
  List<double> monthlyReturns = [];
  List<double> monthlyExpenses = [];
  List<double> monthlyAcresWorked = [];
  List<double> monthlyFuelConsumed= [];
  List<double> monthlyProfit = [];
  @override
  void initState() {
    super.initState();
    _loadMonthlyChartData();
  }
  Future<void> _loadMonthlyChartData() async {
    try {
      int year = DateTime.now().year;
      final data = await _tractorService.getMonthlyTractorStats(
        year: year,
        tractorId: tractor['id'],
      );
      if (data.isNotEmpty) {
        setState(() {
          monthlyChartLabels = data.map((m) => m["month"].toString()).toList();
          monthlyReturns =
              data.map<double>((m) => (m["returnsAmount"] as num).toDouble()).toList();
          monthlyExpenses =
              data.map<double>((m) => (m["expenseAmount"] as num).toDouble()).toList();
          monthlyAcresWorked =
              data.map<double>((m) => (m["acresWorked"] as num).toDouble()).toList();
          monthlyFuelConsumed =
              data.map<double>((m) => (m["fuelLitres"] as num).toDouble()).toList();
          monthlyProfit =
              data.map<double>((m) => (m["totalProfit"] as num).toDouble()).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading monthly chart: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> tractor = widget.tractor;
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    final double screenWidth = MediaQuery.of(context).size.width;

    final String model = (tractor['model'] ?? 'Unknown Model').toString();
    final String serial = (tractor['serialNumber'] ?? '-').toString();
    final String make = (tractor['make'] ?? 'N/A').toString();
    final String status = (tractor['status'] ?? 'Inactive').toString();

    double toDouble(dynamic value) => value == null ? 0.0 : double.tryParse(value.toString()) ?? 0.0;

    final double hp = toDouble(tractor['capacityHp']);
    final double expenses = toDouble(tractor['totalExpenses']);
    final double returns = toDouble(tractor['totalReturns']);
    final double fuel = toDouble(tractor['totalFuelLitres']);
    final double area = toDouble(tractor['totalAreaWorked']);
    final double profit = toDouble(tractor['netProfit']);

    double cardWidth = (screenWidth - 48) / 2;
    if (screenWidth < 350) cardWidth = (screenWidth - 40) / 2;

    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(
        title: Text("$model ($serial)",
            style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: colors.primaryText),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.edit_rounded),
          //   onPressed: () {
          //     debugPrint('Edit button tapped for $model');
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.white.withOpacity(0.05), Colors.transparent]
                      : [Colors.black.withOpacity(0.02), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.agriculture,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$model ($serial)",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: colors.primaryText)),
                        const SizedBox(height: 6),
                        Text("Make: $make | Power: ${hp.toStringAsFixed(0)} HP",
                            style:
                            TextStyle(color: colors.secondaryText, fontSize: 14)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text("Status: ",
                                style: TextStyle(
                                    color: colors.secondaryText, fontSize: 14)),
                            Text(
                              status,
                              style: TextStyle(
                                  color: status == "Active"
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard(
                    "Total Expenses",
                    "₹${expenses.toStringAsFixed(2)}",
                    Icons.money_off,
                    Colors.red,
                    isDark,
                    cardWidth,
                    colors.border),
                _metricCard(
                    "Total Returns",
                    "₹${returns.toStringAsFixed(2)}",
                    Icons.attach_money,
                    Colors.green,
                    isDark,
                    cardWidth,
                    colors.border),
                _metricCard(
                    "Fuel Used",
                    "${fuel.toStringAsFixed(1)} L",
                    Icons.local_gas_station,
                    Colors.orange,
                    isDark,
                    cardWidth,
                    colors.border),
                _metricCard(
                    "Area Worked",
                    "${area.toStringAsFixed(2)} acres",
                    Icons.terrain,
                    Colors.blue,
                    isDark,
                    cardWidth,
                    colors.border),
                _metricCard(
                    "Net Profit",
                    "₹${profit.toStringAsFixed(2)}",
                    Icons.trending_up,
                    profit >= 0 ? Colors.green : Colors.red,
                    isDark,
                    cardWidth,
                    colors.border),
              ],
            ),
            const SizedBox(height: 28),
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
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, bool isDark, double width, Color borderColor) {
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color overlay = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          gradient: LinearGradient(
            colors: [overlay, Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 3),
            Text(title,
                style:
                TextStyle(fontSize: 12.5, color: textColor.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}
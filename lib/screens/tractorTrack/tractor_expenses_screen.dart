import 'dart:developer';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../services/TractorService/tractor_service.dart';
import 'add_entities/add_expense.dart';

class TractorExpensesScreen extends StatefulWidget {
  const TractorExpensesScreen({Key? key}) : super(key: key);

  @override
  State<TractorExpensesScreen> createState() => _TractorExpensesScreenState();
}

class _TractorExpensesScreenState extends State<TractorExpensesScreen> {
  final tractorService = TractorService();

  List<Map<String, dynamic>> tractors = [];
  bool isLoading = true;

  List<double> chartValues = [];
  List<int> chartYears = [];
  int totalInvestment = 0;
  int totalFuel = 0;
  int totalRepair = 0;
  int totalOther = 0;

  @override
  void initState() {
    super.initState();
    _initMethods();
  }

  void _initMethods(){
    _loadChartData();
    _getSummaryData();
  }

  Future<void> _getSummaryData() async {
    setState(() => isLoading = true);
    try{
      final data = await tractorService.getExpenseSummary();
      totalInvestment = data["totalExpense"]!;
      totalFuel = data["fuelExpense"]!;
      totalRepair = data["repairExpense"]!;
      totalOther = data["otherExpense"]!;
    }catch(e){
      debugPrint("Error loading expense Summary data: $e");
    }
  }

  Future<void> _loadChartData() async {
    setState(() => isLoading = true);

    try {
      int currentYear = DateTime.now().year;
      int startYear = currentYear - 5;

      final yearlyList = await tractorService.getYearlyExpenses(
        startYear: startYear,
        endYear: currentYear,
      );

      chartYears = yearlyList.map<int>((y) => y["year"]).toList();
      chartValues =
          yearlyList.map<double>((y) => y["totalYearExpense"]).toList();
    } catch (e) {
      debugPrint("Error loading chart data: $e");
    }

    setState(() => isLoading = false);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: "Yearly Investment (₹)", isDark: isDark),
              const SizedBox(height: 12),

              _InvestmentChart(
                isDark: isDark,
                chartBg: colors.card,
                years: chartYears,
                values: chartValues,
              ),

              const SizedBox(height: 24),

              // -------------------- INFO CARDS --------------------
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.blueAccent,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        label: "Investment",
                        value: "₹${formatIndianNumber(totalInvestment)}",
                        textColor: colors.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.local_gas_station,
                        iconColor: Colors.orange,
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        label: "Fuel",
                        value: "₹${formatIndianNumber(totalFuel)}",
                        textColor: colors.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.build,
                        iconColor: Colors.redAccent,
                        backgroundColor: Colors.redAccent.withOpacity(0.2),
                        label: "Repair",
                        value: "₹${formatIndianNumber(totalRepair)}",
                        textColor: colors.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.more_horiz,
                        iconColor: Colors.green,
                        backgroundColor: Colors.green.withOpacity(0.2),
                        label: "Other",
                        value: "₹${formatIndianNumber(totalOther)}",
                        textColor: colors.text,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Divider(color: colors.divider),
              const SizedBox(height: 16),

              _SectionTitle(title: "Monthly Expenses", isDark: isDark),
              const SizedBox(height: 12),

              ...tractors.expand((t) {
                final monthlyExpenses = List<Map<String, dynamic>>.from(t['monthlyExpenses'] ?? []);
                return monthlyExpenses.map((m) {
                  return Card(
                    color: colors.card,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        "${t['name']} - ${m['month']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      subtitle: Text(
                        "Fuel: ₹${m['fuel']} | Repair: ₹${m['repair']} | Other: ₹${m['other']}",
                        style: TextStyle(
                          color: colors.text.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                });
              }).toList(),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpensePage()),
          ).then((_) => _initMethods());
        },
      ),
    );
  }
}

// -------------------- Info Card --------------------
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;
  final String value;
  final Color textColor;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// -------------------- Section Title --------------------
class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}

// -------------------- Dynamic Investment Chart --------------------
class _InvestmentChart extends StatelessWidget {
  final bool isDark;
  final Color chartBg;
  final List<int> years;
  final List<double> values;

  const _InvestmentChart({
    required this.isDark,
    required this.chartBg,
    required this.years,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chartBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index < 0 || index >= years.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      years[index].toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                  );
                },
              ),
            ),

            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          barGroups: List.generate(
            years.length,
                (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: Colors.blueAccent,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatIndianNumber(num value) {
  if (value >= 10000000) {
    return "${(value / 10000000).toStringAsFixed(1)}Cr";
  } else if (value >= 100000) {
    return "${(value / 100000).toStringAsFixed(1)}L";
  } else if (value >= 1000) {
    return "${(value / 1000).toStringAsFixed(1)}K";
  }
  return value.toStringAsFixed(0);
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

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'add_entities/add_tractor.dart';
import 'details_screen/tractor_details_page.dart';
import '../../services/TractorService/tractor_service.dart';

class TractorDetailsScreen extends StatefulWidget {
  const TractorDetailsScreen({super.key});

  @override
  State<TractorDetailsScreen> createState() => _TractorDetailsScreenState();
}

class _TractorDetailsScreenState extends State<TractorDetailsScreen> {
  final TractorService _tractorService = TractorService();
  List<Map<String, dynamic>> tractors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTractors();
  }

  Future<void> _loadTractors() async {
    final data = await _tractorService.fetchTractors();
    setState(() {
      tractors = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildChartSection(
                    context: context,
                    title: "Yearly Expenses vs Returns (₹)",
                    labels: ["2020", "2021", "2022", "2023", "2024"],
                    firstData: [15000, 17000, 25000, 27000, 31000],
                    secondData: [20000, 22000, 28000, 32000, 40000],
                    firstColor: Colors.redAccent,
                    secondColor: Colors.greenAccent,
                    firstLabel: "Expenses",
                    secondLabel: "Returns",
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  _buildChartSection(
                    context: context,
                    title: "Monthly Fuel Consumption & Area Worked",
                    labels: const [
                      "Jan",
                      "Feb",
                      "Mar",
                      "Apr",
                      "May",
                      "Jun",
                      "Jul",
                      "Aug",
                      "Sep",
                      "Oct",
                      "Nov",
                      "Dec"
                    ],
                    firstData: const [
                      120,
                      140,
                      100,
                      160,
                      180,
                      200,
                      190,
                      170,
                      150,
                      130,
                      120,
                      110
                    ],
                    secondData: const [
                      20,
                      25,
                      22,
                      28,
                      30,
                      32,
                      29,
                      26,
                      25,
                      24,
                      23,
                      22
                    ],
                    firstColor: Colors.orangeAccent,
                    secondColor: Colors.blueAccent,
                    firstLabel: "Fuel (L)",
                    secondLabel: "Area (Acres)",
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.withOpacity(0.3)),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        onPressed: () => _navigateToAddTractor(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChartSection({
    required BuildContext context,
    required String title,
    required List<String> labels,
    required List<double> firstData,
    required List<double> secondData,
    required Color firstColor,
    required Color secondColor,
    required String firstLabel,
    required String secondLabel,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _CombinedBarChart(
          isDark: isDark,
          labels: labels,
          firstData: firstData,
          secondData: secondData,
          firstColor: firstColor,
          secondColor: secondColor,
          firstLabel: firstLabel,
          secondLabel: secondLabel,
        ),
      ],
    );
  }

  void _navigateToAddTractor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTractorPage()),
    );
  }
}

class _CombinedBarChart extends StatelessWidget {
  final bool isDark;
  final List<String> labels;
  final List<double> firstData;
  final List<double> secondData;
  final Color firstColor;
  final Color secondColor;
  final String firstLabel;
  final String secondLabel;

  const _CombinedBarChart({
    required this.isDark,
    required this.labels,
    required this.firstData,
    required this.secondData,
    required this.firstColor,
    required this.secondColor,
    required this.firstLabel,
    required this.secondLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent, // ✅ Transparent background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: firstColor, label: firstLabel),
              const SizedBox(width: 16),
              _LegendDot(color: secondColor, label: secondLabel),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(labels.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: firstData[i],
                        color: firstColor.withOpacity(0.9),
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: secondData[i],
                        color: secondColor.withOpacity(0.9),
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
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

  void _navigateToTractorDetails(BuildContext context, Map<String, dynamic> tractor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TractorDetailPage(tractor: tractor)),
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

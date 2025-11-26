import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TractorDetailPage extends StatelessWidget {
  final Map<String, dynamic> tractor;
  const TractorDetailPage({Key? key, required this.tractor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;

    // 🌿 Match TractorScreen Theme
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color secondaryText =
    isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color borderColor =
    isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

    final double screenWidth = MediaQuery.of(context).size.width;

    final List<String> months = [
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
    ];

    // ✅ Type-safe extraction
    final String model = (tractor['model'] ?? 'Unknown Model').toString();
    final String serial = (tractor['serialNumber'] ?? '-').toString();
    final String make = (tractor['make'] ?? 'N/A').toString();
    final String status = (tractor['status'] ?? 'Inactive').toString();

    double toDouble(dynamic value) =>
        value == null ? 0.0 : double.tryParse(value.toString()) ?? 0.0;

    final double hp = toDouble(tractor['capacityHp']);
    final double expenses = toDouble(tractor['totalExpenses']);
    final double returns = toDouble(tractor['totalReturns']);
    final double fuel = toDouble(tractor['totalFuelLitres']);
    final double area = toDouble(tractor['totalAreaWorked']);
    final double profit = toDouble(tractor['netProfit']);

    final monthlyExpenses = (tractor['monthlyExpenses'] ??
        [1200, 1500, 1600, 1800, 2000, 1900, 1700, 1500, 1400, 1300, 1200, 1100])
        .map<double>((e) => toDouble(e))
        .toList();
    final monthlyReturns = (tractor['monthlyReturns'] ??
        [1500, 1800, 2000, 2200, 2500, 2400, 2200, 2000, 1900, 1700, 1500, 1300])
        .map<double>((e) => toDouble(e))
        .toList();
    final monthlyFuel = (tractor['monthlyFuel'] ??
        [60, 70, 75, 80, 90, 85, 78, 70, 65, 60, 55, 50])
        .map<double>((e) => toDouble(e))
        .toList();
    final monthlyArea = (tractor['monthlyArea'] ??
        [2, 2.3, 2.5, 3, 3.2, 3.5, 3.3, 3, 2.8, 2.5, 2.2, 2])
        .map<double>((e) => toDouble(e))
        .toList();

    double cardWidth = (screenWidth - 48) / 2;
    if (screenWidth < 350) cardWidth = (screenWidth - 40) / 2;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("$model ($serial)",
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌾 Tractor Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
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
                                color: textColor)),
                        const SizedBox(height: 6),
                        Text("Make: $make | Power: ${hp.toStringAsFixed(0)} HP",
                            style:
                            TextStyle(color: secondaryText, fontSize: 14)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text("Status: ",
                                style: TextStyle(
                                    color: secondaryText, fontSize: 14)),
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

            // 💹 Key Metric Cards
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard("Total Expenses", "₹${expenses.toStringAsFixed(2)}",
                    Icons.money_off, Colors.red, isDark, cardWidth, borderColor),
                _metricCard("Total Returns", "₹${returns.toStringAsFixed(2)}",
                    Icons.attach_money, Colors.green, isDark, cardWidth, borderColor),
                _metricCard("Fuel Used", "${fuel.toStringAsFixed(1)} L",
                    Icons.local_gas_station, Colors.orange, isDark, cardWidth, borderColor),
                _metricCard("Area Worked", "${area.toStringAsFixed(2)} acres",
                    Icons.terrain, Colors.blue, isDark, cardWidth, borderColor),
                _metricCard(
                    "Net Profit",
                    "₹${profit.toStringAsFixed(2)}",
                    Icons.trending_up,
                    profit >= 0 ? Colors.green : Colors.red,
                    isDark,
                    cardWidth,
                    borderColor),
              ],
            ),

            const SizedBox(height: 28),

            // 📊 Charts
            _chartSection(
              title: "Monthly Expenses vs Returns",
              labels: months,
              firstData: monthlyExpenses,
              secondData: monthlyReturns,
              firstColor: Colors.redAccent,
              secondColor: Colors.green,
              firstLabel: "Expenses",
              secondLabel: "Returns",
              isDark: isDark,
              borderColor: borderColor,
            ),

            const SizedBox(height: 28),

            _chartSection(
              title: "Monthly Fuel vs Area Worked",
              labels: months,
              firstData: monthlyFuel,
              secondData: monthlyArea,
              firstColor: Colors.orangeAccent,
              secondColor: Colors.blueAccent,
              firstLabel: "Fuel (L)",
              secondLabel: "Area (Acre)",
              isDark: isDark,
              borderColor: borderColor,
            ),
          ],
        ),
      ),
    );
  }

  // 🌾 Metric Card
  Widget _metricCard(String title, String value, IconData icon, Color color,
      bool isDark, double width, Color borderColor) {
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color overlay =
    isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);

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

  // 📈 Chart Section
  Widget _chartSection({
    required String title,
    required List<String> labels,
    required List<double> firstData,
    required List<double> secondData,
    required Color firstColor,
    required Color secondColor,
    required String firstLabel,
    required String secondLabel,
    required bool isDark,
    required Color borderColor,
  }) {
    final double chartHeight = 260;

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
        Container(
          height: chartHeight,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // 🔹 Legend Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(firstColor, firstLabel),
                  const SizedBox(width: 16),
                  _legendDot(secondColor, secondLabel),
                ],
              ),
              const SizedBox(height: 12),

              // 🔹 Chart
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
                          reservedSize: 40,
                          getTitlesWidget: (value, _) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade300   // ✅ brightened for dark mode
                                    : Colors.grey.shade600,   // ✅ softer for light mode
                              ),
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
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: List.generate(labels.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 6,
                        barRods: [
                          BarChartRodData(
                            toY: firstData[i],
                            color: firstColor,
                            width: 10,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          BarChartRodData(
                            toY: secondData[i],
                            color: secondColor,
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
        ),
      ],
    );
  }


  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

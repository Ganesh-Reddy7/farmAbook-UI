import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'add_entities/add_return.dart';
import 'details_screen/client_list.dart'; // Uncomment when AddReturnPage is ready

class TractorReturnsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tractors;
  const TractorReturnsScreen({Key? key, required this.tractors}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = _AppColors(isDark);

    // -------------------- Calculate Totals --------------------
    double totalReturns = 0;
    double totalAreaWorked = 0;
    int totalTrips = 0;

    final List<double> monthlyReturns = List.filled(12, 0); // Jan to Dec

    for (var t in tractors) {
      final monthlyData = List<Map<String, dynamic>>.from(t['monthlyReturns'] ?? []);
      for (var m in monthlyData) {
        totalReturns += (m['returns'] ?? 0);
        totalAreaWorked += (m['areaWorked'] ?? 0);
        // totalTrips += (m['trips'] ?? 0);

        int monthIndex = _monthToIndex(m['month']);
        if (monthIndex >= 0 && monthIndex < 12) {
          monthlyReturns[monthIndex] += (m['returns'] ?? 0);
        }
      }
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------- Monthly Returns Graph --------------------
              _SectionTitle(title: "Monthly Returns", isDark: isDark),
              const SizedBox(height: 12),
              _MonthlyReturnsChart(
                monthlyReturns: monthlyReturns,
                isDark: isDark,
                chartBg: colors.card,
              ),
              const SizedBox(height: 16),

              // -------------------- Info Cards --------------------
              LayoutBuilder(
                builder: (context, constraints) {
                  double spacing = 12;
                  double cardWidth = (constraints.maxWidth - 2 * spacing) / 3;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _ResponsiveInfoCard(
                        width: cardWidth,
                        icon: Icons.attach_money,
                        iconColor: Colors.green,
                        backgroundColor: Colors.green.withOpacity(0.2),
                        label: "Total Returns",
                        value: "₹${totalReturns.toStringAsFixed(0)}",
                        textColor: colors.text,
                      ),
                      _ResponsiveInfoCard(
                        width: cardWidth,
                        icon: Icons.landscape,
                        iconColor: Colors.orange,
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        label: "No.of Acres",
                        value: "${totalAreaWorked.toStringAsFixed(1)} acres",
                        textColor: colors.text,
                      ),
                      _ResponsiveInfoCard(
                        width: cardWidth,
                        icon: Icons.directions_car,
                        iconColor: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        label: "Total Trips",
                        value: "$totalTrips",
                        textColor: colors.text,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // -------------------- Month-wise Returns List --------------------
              _SectionTitle(title: "Returns Details (Current Year)", isDark: isDark),
              const SizedBox(height: 12),
              ...tractors.expand((t) {
                final monthlyData = List<Map<String, dynamic>>.from(t['monthlyReturns'] ?? []);
                return monthlyData.map((m) {
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
                        "Returns: ₹${m['returns']} | Area Worked: ${m['areaWorked']} acres | Trips: ${m['trips']}",
                        style: TextStyle(color: colors.text.withOpacity(0.7)),
                      ),
                    ),
                  );
                }).toList();
              }).toList(),
            ],
          ),
        ),
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // View Clients Button
          FloatingActionButton(
            heroTag: "viewClients",
            backgroundColor: Colors.blueGrey,
            onPressed: () {
              // TODO: Navigate to ViewClientsPage when ready
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewClientsPage()));
            },
            child: const Icon(Icons.people, color: Colors.white),
          ),
          const SizedBox(height: 12),

          // Add Return Button
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

  int _monthToIndex(String month) {
    const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return months.indexOf(month);
  }
}

// -------------------- Monthly Returns Bar Chart --------------------
class _MonthlyReturnsChart extends StatelessWidget {
  final List<double> monthlyReturns;
  final bool isDark;
  final Color chartBg;

  const _MonthlyReturnsChart({
    required this.monthlyReturns,
    required this.isDark,
    required this.chartBg,
  });

  @override
  Widget build(BuildContext context) {
    const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

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
                  if (index < 0 || index >= months.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      months[index],
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
            monthlyReturns.length,
                (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: monthlyReturns[i],
                  color: Colors.greenAccent,
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

// -------------------- Responsive Info Card --------------------
class _ResponsiveInfoCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;
  final String value;
  final Color textColor;

  const _ResponsiveInfoCard({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
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

// -------------------- Theme Colors --------------------
class _AppColors {
  final Color background;
  final Color card;
  final Color text;
  final bool isDark;

  _AppColors(this.isDark)
      : background = isDark ? const Color(0xFF081712) : Colors.white,
        card = isDark ? const Color(0xFF081712) : Colors.grey.shade100,
        text = isDark ? Colors.white : Colors.black87;
}

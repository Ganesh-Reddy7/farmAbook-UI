import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;

    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color accent = isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;
    final Color cardGradientStart = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);
    final Color cardGradientEnd = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);
    final Color cardBorder = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

    final double totalDebt = 50000;
    final double totalLent = 30000;
    final double interestPaid = 2000;
    final double interestReceived = 1500;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: totalDebt,
                    color: Colors.red,
                    title: 'Debt',
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: totalLent,
                    color: Colors.green,
                    title: 'Lent',
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: interestPaid + interestReceived,
                    color: Colors.orange,
                    title: 'Interest',
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Overview of Loans and Interest",
            style: TextStyle(color: primaryText, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

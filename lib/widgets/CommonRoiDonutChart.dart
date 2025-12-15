import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LogRoiDonut extends StatelessWidget {
  final double investment;
  final double returns;
  final bool isDark;

  const LogRoiDonut({
    super.key,
    required this.investment,
    required this.returns,
    required this.isDark,
  });

  double get roiMultiplier {
    if (investment == 0) return 0;
    return returns / investment;
  }

  // Logarithmic scale: up to 100x (10,000% ROI)
  double get logPercentage {
    if (roiMultiplier <= 0) return 0;

    double logValue = log(roiMultiplier) / ln10; // log10
    double logMax = log(100) / ln10; // log10(100) = 2

    return (logValue / logMax).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final color = roiMultiplier >= 1 ? Colors.green : Colors.red;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 70,
              sectionsSpace: 0,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: logPercentage * 100,
                  radius: 25,
                  color: color,
                  title: "",
                ),
                PieChartSectionData(
                  value: (100 - logPercentage * 100),
                  radius: 25,
                  color: Colors.grey.withOpacity(0.2),
                  title: "",
                ),
              ],
            ),
          ),

          // Center Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${(roiMultiplier * 100).toStringAsFixed(1)}%",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "ROI (Log Scale)",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                "x${roiMultiplier.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

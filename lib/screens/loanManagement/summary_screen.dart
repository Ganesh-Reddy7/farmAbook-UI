import 'dart:ui';
import 'package:farmabook/models/lentDto.dart';
import 'package:farmabook/screens/loanManagement/debt_screen.dart';
import 'package:farmabook/screens/loanManagement/lent_screen.dart';
import 'package:farmabook/screens/loanManagement/maturity_bonds_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/loan_service.dart';

class SummaryScreen extends StatefulWidget {
  final VoidCallback? onSeeAllLent;
  final VoidCallback? onSeeAllDebt;
  final VoidCallback? onSeeAllMaturity;

  const SummaryScreen({
    Key? key,
    this.onSeeAllLent,
    this.onSeeAllDebt,
    this.onSeeAllMaturity,
  }) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  List<LentLoanDTO> loans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoans();
  }

  Future<void> fetchLoans() async {
    try {
      final fetchedLoans = await LoanService().getLoansForFarmer();
      setState(() {
        loans = fetchedLoans;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching loans: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;

    // Theme Colors
    final Color scaffoldBg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB);
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color cardGradientStart = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);
    final Color cardGradientEnd = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);

    // Filtered Loan Lists
    final lentLoans = loans.where((l) => l.isGiven == true && l.isClosed == false).toList();
    final debtLoans = loans.where((l) => l.isGiven == false && l.isClosed == false).toList();
    final nearMaturityLoans = loans.where((l) => l.nearMaturity == true && l.isClosed == false).toList();

    double sumPrincipal(List<LentLoanDTO> list) =>
        list.fold(0, (sum, l) => sum + (l.principal ?? 0));
    double sumInterest(List<LentLoanDTO> list) =>
        list.fold(0, (sum, l) => sum + (l.currentInterest ?? 0));

    // Pie Chart Container
    Widget buildPieChartContainer(String title, List<PieChartSectionData> sections, double total, {bool isCount = false}) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: cardGradientStart,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Pie Chart
            SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Progress Bars
            Column(
              children: sections.map((s) {
                double proportion = total > 0 ? s.value / total : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // Color Indicator
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Progress Bar + Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title ?? '',
                              style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: proportion,
                                minHeight: 10,
                                color: s.color,
                                backgroundColor: cardGradientEnd,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),
                      Text(
                        isCount ? "${s.value.toInt()} loans" : "₹${s.value.toInt()}",
                        style: TextStyle(
                            color: primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            Divider(color: cardGradientEnd.withOpacity(0.5)),
            const SizedBox(height: 4),

            // Total
            Text(isCount ? "Total: ${total.toInt()} loans" : "Total: ₹${total.toInt()}",
                style: TextStyle(
                    color: primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );
    }

    // Premium Loan Card
    Widget loanCard(LentLoanDTO loan) {
      final bool isGiven = loan.isGiven ?? false;
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: 250,
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isGiven
                    ? [const Color(0xFF2193b0).withOpacity(0.5), const Color(0xFF6dd5ed).withOpacity(0.5)]
                    : [const Color(0xFFff416c).withOpacity(0.5), const Color(0xFFff4b2b).withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Column: Source + Principal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loan.source ?? "Unknown",
                        style: TextStyle(color: secondaryText, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text("₹${loan.principal?.toStringAsFixed(0) ?? '--'}",
                        style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Center Column: Remaining
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Remaining", style: TextStyle(color: secondaryText, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text("₹${loan.remainingPrincipal?.toStringAsFixed(0) ?? '--'}",
                        style: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                // Right Column: Interest + Maturity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.percent, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text("${loan.interestRate?.toStringAsFixed(1) ?? '--'}%",
                            style: TextStyle(color: primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan.nextMaturityDate ?? "No Date",
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Loan Section with See All
    Widget loanSection(String title, List<LentLoanDTO> list, VoidCallback onSeeAll) {
      if (list.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(onPressed: onSeeAll, child: const Text("See All")),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length > 4 ? 4 : list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => loanCard(list[i]),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildPieChartContainer(
                "Loan Distribution",
                [
                  PieChartSectionData(
                      value: lentLoans.length.toDouble(),
                      color: Colors.greenAccent,
                      title: "Lent"),
                  PieChartSectionData(
                      value: debtLoans.length.toDouble(),
                      color: Colors.redAccent,
                      title: "Debt"),
                ],
                (lentLoans.length + debtLoans.length).toDouble(),
                isCount: true,
              ),
              buildPieChartContainer(
                "Lent Breakdown",
                [
                  PieChartSectionData(
                    value: sumPrincipal(lentLoans),
                    color: Colors.blueAccent,
                    title: "Principal",
                  ),
                  PieChartSectionData(
                    value: sumInterest(lentLoans),
                    color: Colors.orangeAccent,
                    title: "Interest",
                  ),
                ],
                sumPrincipal(lentLoans) + sumInterest(lentLoans),
              ),
              buildPieChartContainer(
                "Debt Breakdown",
                [
                  PieChartSectionData(
                    value: sumPrincipal(debtLoans),
                    color: Colors.redAccent,
                    title: "Principal",
                  ),
                  PieChartSectionData(
                    value: sumInterest(debtLoans),
                    color: Colors.purpleAccent,
                    title: "Interest",
                  ),
                ],
                sumPrincipal(debtLoans) + sumInterest(debtLoans),
              ),
              loanSection(
                "Lent Loans",
                lentLoans,
                widget.onSeeAllLent ?? () {},
              ),
              loanSection(
                "Debt Loans",
                debtLoans,
                widget.onSeeAllDebt ?? () {},
              ),
              loanSection(
                "Near Maturity Loans",
                nearMaturityLoans,
                widget.onSeeAllMaturity ?? () {},
              ),

            ],
          ),
        ),
      ),
    );
  }
}

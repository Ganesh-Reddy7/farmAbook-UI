import 'dart:ui';
import 'package:farmabook/models/lentDto.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/loan_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/slide_route.dart';
import 'calculatorScreen/InterestCalculatorScreen.dart';

class SummaryScreen extends StatefulWidget {
  final VoidCallback? onSeeAllLent;
  final VoidCallback? onSeeAllDebt;
  final VoidCallback? onSeeAllMaturity;

  const SummaryScreen({
    super.key,
    this.onSeeAllLent,
    this.onSeeAllDebt,
    this.onSeeAllMaturity,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  List<LentLoanDTO> loans = [];
  bool isLoading = true;
  int? _touchedIndex;


  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _onRefresh() async {
    setState(() => isLoading = true);
    await _fetchLoans();
  }


  Future<void> _fetchLoans() async {
    try {
      final data = await LoanService().getLoansForFarmer();
      setState(() {
        loans = data;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    final primary = isDark ? Colors.white : Colors.black87;
    final secondary = isDark ? Colors.white70 : Colors.grey.shade600;
    final cardBg = isDark ? Colors.white.withOpacity(0.05) : Colors.white;

    final lent = loans.where((l) => l.isGiven == true && l.isClosed == false).toList();
    final debt = loans.where((l) => l.isGiven == false && l.isClosed == false).toList();
    final near = loans.where((l) => l.nearMaturity == true && l.isClosed == false).toList();

    double sumPrincipal(List<LentLoanDTO> list) => list.fold(0, (s, l) => s + (l.principal ?? 0));

    double sumInterest(List<LentLoanDTO> list) => list.fold(0, (s, l) => s + (l.currentInterest ?? 0));

    return Scaffold(
      backgroundColor: colors.card,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _onRefresh,
          backgroundColor: colors.card,
          color: Colors.green,
          displacement: 80,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _pieSection(
                  title: "Loan Distribution",
                  primary: primary,
                  secondary: secondary,
                  cardBg: cardBg,
                  isCount: true,
                  sections: [
                    _pie(lent.length.toDouble(), Colors.greenAccent, "Lent"),
                    _pie(debt.length.toDouble(), Colors.redAccent, "Debt"),
                  ],
                ),
                _pieSection(
                  title: "Lent Breakdown",
                  primary: primary,
                  secondary: secondary,
                  cardBg: cardBg,
                  sections: [
                    _pie(sumPrincipal(lent), Colors.blueAccent, "Principal"),
                    _pie(sumInterest(lent), Colors.orangeAccent, "Interest"),
                  ],
                ),

                _pieSection(
                  title: "Debt Breakdown",
                  primary: primary,
                  secondary: secondary,
                  cardBg: cardBg,
                  sections: [
                    _pie(sumPrincipal(debt), Colors.redAccent, "Principal"),
                    _pie(sumInterest(debt), Colors.purpleAccent, "Interest"),
                  ],
                ),

                _loanSection(
                  "Lent Loans",
                  lent,
                  primary,
                  secondary,
                  widget.onSeeAllLent,
                ),
                _loanSection(
                  "Debt Loans",
                  debt,
                  primary,
                  secondary,
                  widget.onSeeAllDebt,
                ),
                _loanSection(
                  "Near Maturity Loans",
                  near,
                  primary,
                  secondary,
                  widget.onSeeAllMaturity,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "calculator_fab",
        backgroundColor: Colors.green,
        child: const Icon(Icons.calculate,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.of(context).push(
            SlideFromRightRoute(
              page: const InterestCalculatorScreen(),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  Widget _pieSection({
    required String title,
    required Color primary,
    required Color secondary,
    required Color cardBg,
    required List<PieChartSectionData> sections,
    bool isCount = false,
  }) {
    final total = sections.fold(0.0, (s, e) => s + e.value);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: _card(cardBg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TITLE ─────────────────────────────
          Text(
            title,
            style: TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 40),

          // ── PIE + CENTER TOTAL ────────────────
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final s = entry.value;
                      final isActive = _touchedIndex == index;
                      final hasSelection = _touchedIndex != null;

                      return s.copyWith(
                        title: "",
                        radius: isActive ? 56 : 46,
                        color: !hasSelection
                            ? s.color
                            : isActive
                            ? s.color
                            : s.color.withOpacity(0.45),
                      );
                    }).toList(),
                    centerSpaceRadius: 55,
                    sectionsSpace: 3,
                    borderData: FlBorderData(show: false),
                  ),
                ),

                // CENTER TEXT
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCount ? "Total Loans" : "Total",
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCount
                          ? total.toInt().toString()
                          : "₹${total.toInt()}",
                      style: TextStyle(
                        color: primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Column(
            children: sections.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _touchedIndex =
                    _touchedIndex == index ? null : index;
                  });
                },
                child: _legendRow(
                  s,
                  total,
                  isCount,
                  primary,
                  secondary,
                  isActive: _touchedIndex == index,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(
      PieChartSectionData s,
      double total,
      bool isCount,
      Color primary,
      Color secondary, {
        bool isActive = false,
      }) {
    final double percent = total == 0 ? 0 : s.value / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Color Dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: s.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Label
          Expanded(
            flex: 2,
            child: Text(
              s.title ?? "",
              style: TextStyle(
                color: isActive ? primary : secondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),

          // Fill Percentage Bar
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: isActive ? 12 : 10,
                color: s.color,
                backgroundColor: Colors.grey.withOpacity(0.25),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Percentage
          Text(
            "${(percent * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              color: secondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 10),

          // Value
          Text(
            isCount
                ? "${s.value.toInt()}"
                : "₹${s.value.toInt()}",
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loanSection(
      String title,
      List<LentLoanDTO> list,
      Color primary,
      Color secondary,
      VoidCallback? onSeeAll,
      ) {
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text("See all"),
              ),
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 96, // ✅ proper height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list.length > 5 ? 5 : list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                _loanCardWide(list[i], primary, secondary),
          ),
        ),

        const SizedBox(height: 18),
      ],
    );
  }
  Widget _loanCardWide(
      LentLoanDTO loan,
      Color primary,
      Color secondary,
      ) {
    final bool isGiven = loan.isGiven ?? false;

    final Color accent =
    isGiven ? Colors.greenAccent : Colors.redAccent;

    return Container(
      width: 280, // 🔥 comfortable width
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── TOP ROW ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  loan.source ?? "Unknown",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                "${loan.interestRate?.toStringAsFixed(1) ?? '--'}%",
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // ── AMOUNT ──────────────────────
          Text(
            "₹${loan.principal?.toStringAsFixed(0) ?? '--'}",
            style: TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          // ── FOOTER ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Remaining",
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              Text(
                loan.nextMaturityDate ?? "--",
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _pie(double v, Color c, String t) =>
      PieChartSectionData(value: v, color: c, title: t);

  BoxDecoration _card(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
  );
}

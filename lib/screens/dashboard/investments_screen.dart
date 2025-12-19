import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/investment.dart';
import '../../services/investment_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/slide_route.dart';
import '../../widgets/barChart.dart';
import '../../widgets/commonLineChart.dart';
import '../../widgets/common_bottom_sheet_selector.dart';
import '../../widgets/sectionTitle.dart';
import 'add_entities/add_investment_screen.dart' hide Worker;
import 'worker_list_screen.dart';

class InvestmentsScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;
  final VoidCallback? onDataChanged;

  const InvestmentsScreen({
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.scaffoldBg,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
    this.onDataChanged,
    Key? key,
  }) : super(key: key);

  @override
  _InvestmentsScreenState createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  int _selectedYear = DateTime.now().year;
  bool _isLineChart = false;
  Map<int, List<Investment>> investmentsByYear = {};
  Map<int, double> yearlyInvestments = {};
  List<double> chartInvestments = [];
  List<String> chartYears = [];


  @override
  void initState() {
    super.initState();
    _fetchYearlySummary();
    _fetchInvestmentsForYear(_selectedYear, true);
  }

  Future<void> _fetchYearlySummary() async {
    final fetched = await InvestmentService().getYearlySummaryForFarmer(
      startYear: DateTime.now().year - 4,
      endYear: DateTime.now().year,
    );
    setState(() {
      chartYears = fetched.map<String>((y) => y.year.toString()).toList();
      chartInvestments = fetched.map<double>((y) => y.totalAmount.toDouble()).toList();
      yearlyInvestments = {for (var e in fetched) e.year: e.totalAmount};
    });
  }

  Future<void> _fetchInvestmentsForYear(int year, bool includeWorkers) async {
    final fetched = await InvestmentService().getInvestmentsByFinancialYear(
      year: year,
      includeWorkers: includeWorkers,
    );
    setState(() {
      investmentsByYear[year] = fetched;
    });
  }

  Future<void> _refreshCurrentYearInvestments() async {
    await _fetchInvestmentsForYear(_selectedYear, true);
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    final currentYearInvestments = investmentsByYear[_selectedYear] ?? [];
    final totalInvestment = currentYearInvestments.fold<double>(
      0.0,
          (sum, inv) => sum + inv.amount,
    );
    final totalRemaining = currentYearInvestments.fold<double>(
      0.0,
          (sum, inv) => sum + (inv.remainingAmount ?? 0.0),
    );
    final lastFiveYears = List.generate(5, (i) => DateTime.now().year - i).reversed.toList();
    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: SectionTitle(title: "Investments", isDark: isDark , fontSize:16),
        actions: [
          IconButton(
            icon: Icon(
              _isLineChart ? Icons.bar_chart : Icons.show_chart,
              color: widget.accent,
            ),
            onPressed: () => setState(() => _isLineChart = !_isLineChart),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCurrentYearInvestments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              if(_isLineChart)
                  CommonLineChart(
                  isDark: isDark,
                  labels: chartYears,
                  values: chartInvestments,
                  legend1: "Total Investment",
                  lineColor1: Colors.orange,
                )
              else
                CommonBarChart(
                  isDark: isDark,
                  chartBg: colors.card,
                  labels: chartYears,
                  values: chartInvestments,
                  legend1: "Total Investment",
                  barColor: Colors.orange,
                  barWidth: 16,
                ),
              const SizedBox(height: 12),
              Divider(color: colors.divider),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionTitle(title: "Select Year:", isDark: isDark , fontSize:16),
                  GestureDetector(
                    onTap: () async {
                      final selectedYear = await CommonBottomSheetSelector.show<int>(
                        context: context,
                        title: "Select Year",
                        items: lastFiveYears,
                        displayText: (year) => year.toString(),
                        backgroundColor: colors.card,
                        textColor: widget.primaryText,
                        selected: _selectedYear,
                      );
                      if (selectedYear != null) {
                        setState(() => _selectedYear = selectedYear);
                        _fetchInvestmentsForYear(selectedYear, true);
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          _selectedYear.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_drop_down, color: widget.primaryText),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _totalAndPendingCard(totalInvestment, totalRemaining),
              const SizedBox(height: 20),
              _investmentPieChart(currentYearInvestments, totalInvestment),
              const SizedBox(height: 20),
              SectionTitle(title: "Investments in $_selectedYear:", isDark: isDark , fontSize:16),
              const SizedBox(height: 20),
              currentYearInvestments.isEmpty
                  ? _noInvestmentsCard()
                  : Column(children: currentYearInvestments.map((inv) => _investmentCard(inv)).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: widget.accent,
        heroTag: "add-investment",
        onPressed: () async {
          final result = await Navigator.of(context).push(
            SlideFromRightRoute(
              page: AddInvestmentScreen(
              ),
            ),
          );
          if (result == true) {
            _refreshCurrentYearInvestments();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _totalAndPendingCard(double total, double pending) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            widget.cardGradientStart.withOpacity(0.1),
            widget.cardGradientEnd.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _totalPendingColumn(
              icon: Icons.account_balance_wallet,
              iconBg: widget.accent.withOpacity(0.2),
              amount: total,
              title: "Total Investment",
              amountColor: widget.accent),
          Container(width: 1, height: 60, color: widget.cardBorder.withOpacity(0.3)),
          _totalPendingColumn(
              icon: Icons.pending_actions,
              iconBg: Colors.orange.withOpacity(0.2),
              amount: pending,
              title: "Pending Amount",
              amountColor: Colors.orange.shade700),
        ],
      ),
    );
  }

  Column _totalPendingColumn(
      {required IconData icon,
        required Color iconBg,
        required double amount,
        required String title,
        required Color amountColor}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: amountColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: widget.secondaryText)),
        const SizedBox(height: 4),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor),
        ),
      ],
    );
  }

  Widget _investmentPieChart(List<Investment> investments, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: widget.cardGradientStart.withOpacity(0.05),
        border: Border.all(color: widget.cardBorder),
      ),
      child: SizedBox(
        height: 220,
        child: investments.isEmpty
            ? Center(
          child: Text(
            "No pie chart data available",
            style: TextStyle(
                color: widget.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        )
            : PieChart(
          PieChartData(
            sections: investments.map((inv) {
              final percentage = total > 0 ? (inv.amount / total) * 100 : 0.0;
              return PieChartSectionData(
                value: inv.amount,
                color: Colors.primaries[investments.indexOf(inv) % Colors.primaries.length],
                title:
                "${inv.description}\n₹${inv.amount.toStringAsFixed(0)}\n${percentage.toStringAsFixed(1)}%",
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }

  Widget _noInvestmentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.cardGradientStart.withOpacity(0.1),
            widget.cardGradientEnd.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 40, color: widget.accent),
          const SizedBox(height: 12),
          Text(
            "No investments available",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: widget.secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            "Please add investments to view details.",
            style: TextStyle(color: widget.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _investmentCard(Investment inv) {
    final bool hasWorkers = inv.workers != null && inv.workers!.isNotEmpty;

    final double screenW = MediaQuery.of(context).size.width;

    // Dynamic responsive sizes
    final double iconBox = screenW < 360 ? 34 : 40;
    final double titleSize = screenW < 360 ? 14 : 15;
    final double dateSize = screenW < 360 ? 12 : 13;
    final double statusSize = screenW < 360 ? 12.5 : 13.5;
    final double amountSize = screenW < 360 ? 16 : 17;

    final Color paidColor = Colors.green.shade600;
    final Color remainingColor = Colors.orange.shade700;

    return GestureDetector(
      onTap: () {
        if (hasWorkers) {
          Navigator.of(context).push(
            SlideFromRightRoute(
              page: WorkerListScreen(
                investment: inv,
                accent: widget.accent,
                primaryText: widget.primaryText,
                secondaryText: widget.secondaryText,
                scaffoldBg: widget.scaffoldBg,
                cardGradientStart: widget.cardGradientStart,
                cardGradientEnd: widget.cardGradientEnd,
                cardBorder: widget.cardBorder,
              ),
            ),
          );
        }
      },
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: widget.cardGradientStart.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.cardBorder.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(2, 3),
              )
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT ICON
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.work_outline,
                  color: widget.accent,
                  size: iconBox * 0.55, // Responsive icon size
                ),
              ),

              const SizedBox(width: 14),

              // MIDDLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      inv.description,
                      style: TextStyle(
                        color: widget.primaryText,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // DATE
                    Text(
                      "Date: ${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}-${inv.date.day.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        color: widget.secondaryText,
                        fontSize: dateSize,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // STATUS
                    if (inv.remainingAmount != null)
                      Text(
                        inv.remainingAmount! > 0
                            ? "Remaining: ₹${inv.remainingAmount!.toStringAsFixed(0)}"
                            : "Fully Paid",
                        style: TextStyle(
                          fontSize: statusSize,
                          fontWeight: FontWeight.w600,
                          color: inv.remainingAmount! > 0
                              ? remainingColor
                              : paidColor,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // RIGHT SIDE
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // AMOUNT
                  Text(
                    "₹${inv.amount.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: amountSize,
                      fontWeight: FontWeight.bold,
                      color: widget.accent,
                    ),
                  ),

                  if (hasWorkers) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 18,
                          color: widget.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${inv.workers!.length}",
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    )
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

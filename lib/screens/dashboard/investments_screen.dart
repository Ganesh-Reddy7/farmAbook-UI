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
  final VoidCallback? onDataChanged;

  const InvestmentsScreen({
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
      backgroundColor: colors.card,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryText),
        title: SectionTitle(title: "Investments", isDark: isDark , fontSize:16),
        actions: [
          IconButton(
            icon: Icon(
              _isLineChart ? Icons.bar_chart : Icons.show_chart,
              color: colors.accent,
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
                        textColor: colors.primaryText,
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
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_drop_down, color: colors.primaryText),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _totalAndPendingCard(totalInvestment, totalRemaining , colors),
              const SizedBox(height: 20),
              _investmentPieChart(currentYearInvestments, totalInvestment , colors),
              const SizedBox(height: 20),
              SectionTitle(title: "Investments in $_selectedYear:", isDark: isDark , fontSize:16),
              const SizedBox(height: 20),
              currentYearInvestments.isEmpty
                  ? _noInvestmentsCard(colors)
                  : Column(children: currentYearInvestments.map((inv) => _investmentCard(inv , colors)).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: colors.accent,
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

  Widget _totalAndPendingCard(double total, double pending , AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colors.cardGradientStart.withOpacity(0.1),
            colors.cardGradientEnd.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colors.border.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _totalPendingColumn(
              icon: Icons.account_balance_wallet,
              iconBg: colors.accent.withOpacity(0.2),
              amount: total,
              title: "Total Investment",
              amountColor: colors.accent,
              colors: colors
          ),
          Container(width: 1, height: 60, color: colors.border.withOpacity(0.3)),
          _totalPendingColumn(
              icon: Icons.pending_actions,
              iconBg: Colors.orange.withOpacity(0.2),
              amount: pending,
              title: "Pending Amount",
              amountColor: Colors.orange.shade700,
              colors: colors
          ),
        ],
      ),
    );
  }

  Column _totalPendingColumn(
      {required IconData icon,
        required Color iconBg,
        required double amount,
        required String title,
        required Color amountColor,
        required AppColors colors
      }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: amountColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: colors.secondaryText)),
        const SizedBox(height: 4),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor),
        ),
      ],
    );
  }

  Widget _investmentPieChart(List<Investment> investments, double total , AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colors.cardGradientStart.withOpacity(0.05),
        border: Border.all(color: colors.border),
      ),
      child: SizedBox(
        height: 220,
        child: investments.isEmpty
            ? Center(
          child: Text(
            "No pie chart data available",
            style: TextStyle(
                color: colors.secondaryText,
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

  Widget _noInvestmentsCard(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.cardGradientStart.withOpacity(0.1),
            colors.cardGradientEnd.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 40, color: colors.accent),
          const SizedBox(height: 12),
          Text(
            "No investments available",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: colors.secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            "Please add investments to view details.",
            style: TextStyle(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _investmentCard(Investment inv , AppColors colors) {
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
            color: colors.cardGradientStart.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withOpacity(0.25)),
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
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.work_outline,
                  color: colors.accent,
                  size: iconBox * 0.55,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.description,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Date: ${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}-${inv.date.day.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: dateSize,
                      ),
                    ),

                    const SizedBox(height: 6),

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

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // AMOUNT
                  Text(
                    "₹${inv.amount.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: amountSize,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),

                  if (hasWorkers) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 18,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${inv.workers!.length}",
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.accent,
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

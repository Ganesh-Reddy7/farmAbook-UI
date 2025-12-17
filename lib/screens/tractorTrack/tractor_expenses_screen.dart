import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../services/TractorService/tractor_service.dart';
import '../../utils/formatIndianNumber.dart';
import '../../utils/slide_route.dart';
import '../../widgets/no_data_widget.dart';
import '../../widgets/sectionTitle.dart';
import 'add_entities/add_expense.dart';
import '../../widgets/barChart.dart';
import '../../widgets/tractorInfoCard.dart';

class TractorExpensesScreen extends StatefulWidget {
  const TractorExpensesScreen({Key? key}) : super(key: key);

  @override
  State<TractorExpensesScreen> createState() => _TractorExpensesScreenState();
}

class _TractorExpensesScreenState extends State<TractorExpensesScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  final tractorService = TractorService();

  List<Map<String, dynamic>> tractors = [];
  List<double> chartValues = [];
  List<int> chartYears = [];
  List<double> monthlyChartValues = [];
  List<String> monthlyChartLabels = [];

  int totalInvestment = 0;
  int totalFuel = 0;
  int totalRepair = 0;
  int totalOther = 0;

  String selectedFilter = "yearly";
  int? selectedYear;
  int? selectedMonth;
  final List<int> _memoYears = List.generate(6, (i) => DateTime.now().year - i);
  final List<int> _memoMonths = List.generate(12, (i) => i + 1);

  Future<List<Expense>>? expensesFuture;

  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _initMethods();
  }
  Future<void> _initMethods() async {
    await _loadChartData();
    _loadMonthlyChartData();
    _getSummaryData();
    _loadExpenses();
  }
  void _loadExpenses() {
    if (selectedFilter != "all" && selectedYear == null) {
      selectedYear = DateTime.now().year;
    }
    if (selectedFilter == "monthly" && selectedMonth == null) {
      selectedMonth = DateTime.now().month;
    }
    setState(() {
      expensesFuture = tractorService.getExpenses(
        filter: selectedFilter,
        year: selectedFilter != "all" ? selectedYear : null,
        month: selectedFilter == "monthly" ? selectedMonth : null,
      );
    });
  }

  Future<void> _getSummaryData() async {
    setState(() => isLoading = true);
    try {
      final data = await tractorService.getExpenseSummary();
      // keep identical assignments
      totalInvestment = data["totalExpense"] ?? 0;
      totalFuel = data["fuelExpense"] ?? 0;
      totalRepair = data["repairExpense"] ?? 0;
      totalOther = data["otherExpense"] ?? 0;
    } catch (e) {
      debugPrint("Error loading expense Summary data: $e");
    } finally {
      setState(() => isLoading = false);
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
      chartYears = yearlyList.map<int>((y) => y["year"] as int).toList();
      chartValues =
          yearlyList.map<double>((y) => (y["totalYearExpense"] as num).toDouble()).toList();
    } catch (e) {
      debugPrint("Error loading chart data: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadMonthlyChartData() async {
    try {
      int year = DateTime.now().year;
      final data = await tractorService.getYearlyExpenses(
        startYear: year,
        endYear: year,
      );
      if (data.isNotEmpty) {
        final months = data[0]["monthlyExpenses"] as List<dynamic>;

        monthlyChartLabels = monthlyChartLabels = months.map((m) {
          final s = m["month"].toString();
          return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
        }).toList();

        monthlyChartValues =
            months.map<double>((m) => (m["total"] as num).toDouble()).toList();
      }
    } catch (e) {
      debugPrint("Error loading monthly chart: $e");
    }
  }

  void _openFilterSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = _AppColors(isDark);
    final Color accentColor = Colors.green.shade700;

    String tmpFilter = selectedFilter;
    int? tmpYear = selectedYear ?? DateTime.now().year;
    int? tmpMonth = selectedMonth ?? DateTime.now().month;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setSheetState) {
          Future<int?> _showThemedOptionSelector({
            required String title,
            required List<int> items,
            required int? currentSelected,
            required String Function(int) displayFormatter,
            bool isMonth = false,
          }) async {
            return await showModalBottomSheet<int>(
              context: context,
              backgroundColor: colors.background,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMonth ? 4 : 3,
                              childAspectRatio: 2.0,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: items.length,
                            itemBuilder: (_, index) {
                              final item = items[index];
                              final isSelected = item == currentSelected;
                              return GestureDetector(
                                onTap: () => Navigator.pop(ctx, item),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? accentColor : colors.card,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? accentColor : colors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    displayFormatter(item),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : colors.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          final List<Map<String, dynamic>> filterOptions = [
            {'value': 'monthly', 'display': 'Monthly'},
            {'value': 'yearly', 'display': 'Yearly'},
            {'value': 'all', 'display': 'All Time'},
          ];

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.text.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    "Filter Expenses",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Type CHIPS
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "View Filter",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.text.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 10.0,
                    children: filterOptions.map((option) {
                      final isSelected = tmpFilter == option['value'];
                      return ChoiceChip(
                        label: Text(option['display'] as String),
                        selected: isSelected,
                        selectedColor: accentColor,
                        backgroundColor: colors.card,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : colors.text.withOpacity(0.8),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: isSelected ? BorderSide.none : BorderSide(color: colors.divider),
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() {
                              tmpFilter = option['value'] as String;
                              if (tmpFilter == "all") {
                                tmpYear = null;
                                tmpMonth = null;
                              } else {
                                if (tmpFilter == "yearly") tmpMonth = null;
                                tmpYear ??= DateTime.now().year;
                                if (tmpFilter == "monthly") tmpMonth ??= DateTime.now().month;
                              }
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  if (tmpFilter != "all") ...[
                    GestureDetector(
                      onTap: () async {
                        final selected = await _showThemedOptionSelector(
                          title: "Select Year",
                          items: _memoYears,
                          currentSelected: tmpYear,
                          displayFormatter: (y) => "$y",
                        );
                        if (selected != null) setSheetState(() => tmpYear = selected);
                      },
                      child: _buildSelectorField(
                        label: "Year",
                        value: tmpYear?.toString() ?? "Select Year",
                        colors: colors,
                        accentColor: accentColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (tmpFilter == "monthly")
                    GestureDetector(
                      onTap: () async {
                        final selected = await _showThemedOptionSelector(
                          title: "Select Month",
                          items: _memoMonths,
                          currentSelected: tmpMonth,
                          displayFormatter: monthName,
                          isMonth: true,
                        );
                        if (selected != null) setSheetState(() => tmpMonth = selected);
                      },
                      child: _buildSelectorField(
                        label: "Month",
                        value: tmpMonth != null ? monthName(tmpMonth!) : "Select Month",
                        colors: colors,
                        accentColor: accentColor,
                      ),
                    ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Apply changes (kept identical)
                            selectedFilter = tmpFilter;
                            selectedYear = tmpFilter != "all" ? tmpYear : null;
                            selectedMonth = tmpFilter == "monthly" ? tmpMonth : null;

                            Navigator.pop(ctx);
                            (_loadExpenses)();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: const Text("Apply Filter"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String value,
    required _AppColors colors,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: colors.text.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.text.withOpacity(value.startsWith("Select") ? 0.5 : 1),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: accentColor),
            ],
          ),
        ),
      ],
    );
  }

  String _getExpenseTitleForUI() {
    if (selectedFilter == "monthly") {
      if (selectedMonth != null && selectedYear != null) {
        return "Expenses for ${monthName(selectedMonth!)} $selectedYear";
      } else {
        return "Expenses";
      }
    } else if (selectedFilter == "yearly") {
      if (selectedYear != null) {
        return "Expenses for Year $selectedYear";
      } else {
        return "Expenses";
      }
    } else {
      return "All Expenses";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
        child: RefreshIndicator(
          color: scaffoldBg,
          strokeWidth: 2.5,
          onRefresh: () async {
            _initMethods();
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(title: "Yearly Investment (₹)", isDark: isDark),
                const SizedBox(height: 12),
                CommonBarChart(
                  isDark: isDark,
                  chartBg: colors.card,
                  labels: chartYears.map((e) => e.toString()).toList(),
                  values: chartValues,
                  legend1:"Total Yearly Investment",
                  barColor: Colors.blueAccent,
                  barWidth: 20,
                ),
                const SizedBox(height: 24),
                Divider(color: colors.divider),
                const SizedBox(height: 12),
                SectionTitle(title: "Monthly Investment (₹)", isDark: isDark),
                const SizedBox(height: 12),

                CommonBarChart(
                  isDark: isDark,
                  chartBg: colors.card,
                  labels: monthlyChartLabels,
                  values: monthlyChartValues,
                  legend1:"Total Monthly Investment",
                  barColor: Colors.redAccent,
                  barWidth: 14,
                ),
                const SizedBox(height: 24),
                Divider(color: colors.divider),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InfoCard(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: Colors.blueAccent,
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          label: "Investment",
                          value: "₹${NumberUtils.formatIndianNumber(totalInvestment)}",
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.local_gas_station,
                          iconColor: Colors.orange,
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          label: "Fuel",
                          value: "₹${NumberUtils.formatIndianNumber(totalFuel)}",
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.build,
                          iconColor: Colors.redAccent,
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                          label: "Repair",
                          value: "₹${NumberUtils.formatIndianNumber(totalRepair)}",
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.more_horiz,
                          iconColor: Colors.green,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          label: "Other",
                          value: "₹${NumberUtils.formatIndianNumber(totalOther)}",
                          textColor: colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Divider(color: colors.divider),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getExpenseTitleForUI(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    IconButton(
                      onPressed: _openFilterSheet,
                      icon: const Icon(Icons.filter_list),
                      color: colors.text,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                FutureBuilder<List<Expense>>(
                  future: expensesFuture,
                  builder: (context, snapshot) {
                    final theme = Theme.of(context);
                    final isDark = theme.brightness != Brightness.dark;
                    final colors = _AppColors(isDark);
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: Colors.green)),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Error loading expenses: ${snapshot.error}",
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      );
                    }
                    final expenses = snapshot.data ?? [];
                    if (expenses.isEmpty) {
                      return NoDataWidget(
                        message: "No Expenses found for selected filter",
                        isDark: isDark,
                      );
                    }
                    // For grouped views (yearly/all) we build grouped lists.
                    if (selectedFilter == "monthly") {
                      return Column(
                        children: List.generate(expenses.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _ExpenseListItem(
                              expense: expenses[index],
                              primaryText: colors.text,
                              cardColor: colors.card,
                              dividerColor: colors.divider,
                            ),
                          );
                        }),
                      );
                    }
                    // Group for yearly/all
                    final Map<String, List<Expense>> grouped = {};
                    for (final e in expenses) {
                      final key = "${e.expenseDate.year}-${e.expenseDate.month}";
                      grouped.putIfAbsent(key, () => []).add(e);
                    }

                    final sortedKeys = grouped.keys.toList()
                      ..sort((a, b) {
                        final partsA = a.split('-').map(int.parse).toList();
                        final partsB = b.split('-').map(int.parse).toList();
                        final da = DateTime(partsA[0], partsA[1]);
                        final db = DateTime(partsB[0], partsB[1]);
                        return db.compareTo(da);
                      });

                    return Column(
                      children: List.generate(sortedKeys.length, (groupIndex) {
                        final key = sortedKeys[groupIndex];
                        final parts = key.split('-');
                        final year = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final list = grouped[key]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (groupIndex > 0) const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${monthName(month)} $year",
                                style: TextStyle(
                                    color: colors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),

                            ...List.generate(list.length, (index) {
                              return Column(
                                children: [
                                  _ExpenseListItem(
                                    expense: list[index],
                                    primaryText: colors.text,
                                    cardColor: colors.card,
                                    dividerColor: colors.divider,
                                  ),
                                  if (index < list.length - 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                      child: Divider(color: colors.divider.withOpacity(0.4), height: 1.0),
                                    ),
                                ],
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 50)
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(context).push(
            SlideFromRightRoute(
              page: const AddExpensePage(),
            ),
          ).then((_) => _initMethods());
        },
      ),
    );
  }
}

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
    final int itemCount = years.length.clamp(0, values.length);

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
            itemCount,
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

class _ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final Color primaryText;
  final Color cardColor;
  final Color dividerColor;

  const _ExpenseListItem({
    required this.expense,
    required this.primaryText,
    required this.cardColor,
    required this.dividerColor,
  });

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fuel':
        return Colors.orange.shade600;
      case 'repair':
        return Colors.red.shade600;
      case 'maintenance':
        return Colors.blue.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(expense.type);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vertical Type Indicator
          Container(
            width: 4,
            height: 55,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Type and Notes/Description on the first line
                  Row(
                    children: [
                      Text(
                        expense.type,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          expense.notes.isNotEmpty ? expense.notes : "No notes.",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date on the second line
                  Text(
                    formatDate(expense.expenseDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryText.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trailing Cost/Amount
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              "₹${expense.cost.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

// -------------------- Helpers --------------------
String monthName(int m) {
  const list = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  return list[m - 1];
}

String formatDate(DateTime dt) {
  return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
}


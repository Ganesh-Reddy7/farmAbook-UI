import 'package:farmabook/utils/formatIndianNumber.dart';
import 'package:farmabook/widgets/barChart.dart';
import 'package:farmabook/widgets/sectionTitle.dart';
import 'package:farmabook/widgets/tractorInfoCard.dart';
import 'package:flutter/material.dart';
import '../../services/TractorService/tractor_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/slide_route.dart';
import '../../widgets/no_data_widget.dart';
import 'add_entities/add_close_payment.dart';
import 'add_entities/add_return.dart';
import 'details_screen/client_list.dart';

class TractorReturnsScreen extends StatefulWidget {
  const TractorReturnsScreen({Key? key}) : super(key: key);

  @override
  State<TractorReturnsScreen> createState() => _TractorReturnsScreenState();
}

class _TractorReturnsScreenState extends State<TractorReturnsScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  List<Map<String, dynamic>> tractors = [];
  bool isLoading = false;
  double totalReturns = 0;
  double receivedAmount = 0;
  double balanceAmount = 0;
  double totalAreaWorked = 0;
  int currentYear = 0;
  List<double> chartValues = [];
  List<int> chartYears = [];
  List<double> monthlyChartValues = [];
  List<String> monthlyChartLabels = [];
  List<double> monthlyChartValuesReceived = [];
  List<double> monthlyReturns = List.filled(12, 0);
  final tractorService = TractorService();

  String selectedFilter = "yearly";
  int? selectedYear;
  int? selectedMonth;
  final List<int> _memoYears = List.generate(6, (i) => DateTime.now().year - i);
  final List<int> _memoMonths = List.generate(12, (i) => i + 1);
  // RETURNS data
  Map<String, dynamic>? returnsResponse;
  List<dynamic> allActivities = [];
  List<dynamic> pendingActivities = [];
  List<dynamic> partiallyPaidActivities = [];
  List<dynamic> paidActivities = [];
  String selectedTab = "ALL";
  bool isListLoading = false;

  String sortType = "none"; // none | low_to_high | high_to_low
  IconData sortIcon = Icons.swap_vert;

  @override
  void initState() {
    super.initState();
    _loadReturnsData();
  }

  Future<void> _loadReturnsData() async {
    await _loadChartData();
    await _loadMonthlyChartData();
    _loadReturnsDataList();
  }

  Future<void> _loadChartData() async {
    setState(() => isLoading = true);
    try {
      int currentYear = DateTime.now().year;
      int startYear = currentYear - 5;
      final yearlyList = await tractorService.getYearlyReturns(
        startYear: startYear,
        endYear: currentYear,
      );
      chartYears = yearlyList.map<int>((y) => y["year"] as int).toList();
      chartValues = yearlyList.map<double>((y) => (y["totalYearAmount"] as num).toDouble()).toList();
    } catch (e) {
      debugPrint("Error loading chart data: $e");
    }

    setState(() => isLoading = false);
  }
  Future<void> _loadMonthlyChartData() async {
    try {
      int year = DateTime.now().year;
      final data = await tractorService.getYearlyReturns(
        startYear: year,
        endYear: year,
        isSummary: true
      );
      if (data.isNotEmpty) {
        final months = data[0]["monthlyActivities"] as List<dynamic>;
        monthlyChartLabels = monthlyChartLabels = months.map((m) {
          final s = m["month"].toString();
          return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
        }).toList();
        monthlyChartValues = months.map<double>((m) => (m["total"] as num).toDouble()).toList();
        monthlyChartValuesReceived = months.map<double>((m) => (m["received"] as num).toDouble()).toList();
        totalReturns = data[0]["totalYearAmount"];
        totalAreaWorked = data[0]["totalYearAcres"];
        receivedAmount = data[0]["totalYearReceived"];
        balanceAmount = data[0]["totalYearRemaining"];
        currentYear = year;
      }
    } catch (e) {
      debugPrint("Error loading monthly chart: $e");
    }
  }


  Future<void> _loadReturnsDataList() async {
    setState(() => isListLoading = true);

    try {
      if (selectedFilter != "all" && selectedYear == null) selectedYear = DateTime.now().year;
      if (selectedFilter == "monthly" && selectedMonth == null) selectedMonth = DateTime.now().month;

      final response = await tractorService.getReturns(
        filter: selectedFilter,
        year: selectedFilter != "all" ? selectedYear : null,
        month: selectedFilter == "monthly" ? selectedMonth : null,
      );

      if (response is Map<String, dynamic>) {
        returnsResponse = response;
        _processReturnsResponse(response);
      }
    } catch (e) {
      debugPrint("Error loading returns: $e");
    } finally {
      setState(() => isListLoading = false);
    }
  }


  void _processReturnsResponse(Map<String, dynamic> data) {
    allActivities = List<dynamic>.from(data["activities"] ?? []);
    final statusWise = data["statusWise"] as Map<String, dynamic>? ?? {};
    pendingActivities = List<dynamic>.from(statusWise["PENDING"] ?? []);
    partiallyPaidActivities = List<dynamic>.from(statusWise["PARTIALLY_PAID"] ?? []);
    paidActivities = List<dynamic>.from(statusWise["PAID"] ?? []);
    // ensure UI shows something and reset selectedTab if needed
    if (selectedTab == "PENDING" && pendingActivities.isEmpty) selectedTab = "ALL";
    if (selectedTab == "PARTIALLY_PAID" && partiallyPaidActivities.isEmpty) selectedTab = "ALL";
    if (selectedTab == "PAID" && paidActivities.isEmpty) selectedTab = "ALL";

    setState(() {});
  }
  void _openFilterSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    final Color accentColor = Colors.green.shade700;

    String tmpFilter = selectedFilter;
    int? tmpYear = selectedYear ?? DateTime.now().year;
    int? tmpMonth = selectedMonth ?? DateTime.now().month;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
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
              backgroundColor: colors.card,
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
                            selectedFilter = tmpFilter;
                            selectedYear = tmpFilter != "all" ? tmpYear : null;
                            selectedMonth = tmpFilter == "monthly" ? tmpMonth : null;

                            Navigator.pop(ctx);
                            (_loadReturnsDataList)();
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
    required AppColors colors,
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
        return "Returns for ${monthName(selectedMonth!)} $selectedYear";
      } else {
        return "Returns";
      }
    } else if (selectedFilter == "yearly") {
      if (selectedYear != null) {
        return "Returns for Year $selectedYear";
      } else {
        return "Returns";
      }
    } else {
      return "All Returns";
    }
  }

  Widget _buildStatusTabs(AppColors colors) {
    final tabs = [
      {"key": "ALL", "label": "All", "count": allActivities.length},
      {"key": "PENDING", "label": "Pending", "count": pendingActivities.length},
      {"key": "PARTIALLY_PAID", "label": "Partially Paid", "count": partiallyPaidActivities.length},
      {"key": "PAID", "label": "Paid", "count": paidActivities.length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final bool isActive = selectedTab == tab["key"];
          return GestureDetector(
            onTap: () => setState(() => selectedTab = tab["key"] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade700 : colors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? Colors.green.shade700 : colors.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    tab["label"] as String,
                    style: TextStyle(
                      color: isActive ? Colors.white : colors.text,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white24 : Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${tab["count"]}",
                      style: TextStyle(
                        color: isActive ? Colors.white : colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReturnsList(AppColors colors) {
    bool isDark = colors.text == Colors.white;

    List<dynamic> listToShow = [];

    if (selectedTab == "ALL") {
      listToShow = List.from(allActivities);
    } else if (selectedTab == "PENDING") {
      listToShow = List.from(pendingActivities);
    } else if (selectedTab == "PARTIALLY_PAID") {
      listToShow = List.from(partiallyPaidActivities);
    } else if (selectedTab == "PAID") {
      listToShow = List.from(paidActivities);
    }

    // APPLY SORTING
    listToShow = _sortList(listToShow);

    if (listToShow.isEmpty) {
      return NoDataWidget(
        message: "No returns found for selected filter",
        isDark: isDark,
      );
    }

    if (selectedFilter == "monthly") {
      return Column(
        children: listToShow.map((e) {
          return _ReturnListItem(
            activity: e,
            textColor: colors.text,
            cardColor: colors.card,
            dividerColor: colors.divider,
          );
        }).toList(),
      );
    }

    // ---------- YEARLY / ALL TIME GROUPED ----------
    final Map<String, List<dynamic>> grouped = {};

    for (final a in listToShow) {
      final dt = DateTime.parse(a["activityDate"]);
      final key = "${dt.year}-${dt.month}";
      grouped.putIfAbsent(key, () => []).add(a);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aa = a.split('-').map(int.parse).toList();
        final bb = b.split('-').map(int.parse).toList();
        return DateTime(bb[0], bb[1]).compareTo(DateTime(aa[0], aa[1]));
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedKeys.map((key) {
        final year = int.parse(key.split('-')[0]);
        final month = int.parse(key.split('-')[1]);

        // SORT inside each group
        final sortedList = _sortList(grouped[key]!);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${monthName(month)} $year",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),

            const SizedBox(height: 8),

            ...sortedList.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReturnListItem(
                activity: e,
                textColor: colors.text,
                cardColor: colors.card,
                dividerColor: colors.divider,
              ),
            )),
          ],
        );
      }).toList(),
    );
  }


  void _openSortSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Sort By Amount",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold , color: Colors.white),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.arrow_downward , color: Colors.white),
              title: const Text("Low → High"),
              textColor: Colors.white,
              onTap: () {
                setState(() {
                  sortType = "low_to_high";
                  sortIcon = Icons.arrow_downward;
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.arrow_upward , color: Colors.white),
              title: const Text("High → Low"),
              textColor: Colors.white,
              onTap: () {
                setState(() {
                  sortType = "high_to_low";
                  sortIcon = Icons.arrow_upward;
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.close , color: Colors.white),
              title: const Text("Clear Sort"),
              textColor: Colors.white,
              onTap: () {
                setState(() {
                  sortType = "none";
                  sortIcon = Icons.swap_vert;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
  List<dynamic> _sortList(List<dynamic> list) {
    if (sortType == "none") return list;

    list.sort((a, b) {
      final aAmount = (a["amountEarned"] ?? 0).toDouble();
      final bAmount = (b["amountEarned"] ?? 0).toDouble();

      if (sortType == "low_to_high") {
        return aAmount.compareTo(bAmount);
      } else {
        return bAmount.compareTo(aAmount);
      }
    });

    return list;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    if (isLoading) {
      return Scaffold(
        backgroundColor: colors.card,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.card,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.card,
          strokeWidth: 2.5,
          onRefresh: () async {
            _loadReturnsData();
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: "Yearly Returns (₹)", isDark: isDark),
              const SizedBox(height: 12),
              CommonBarChart(
                isDark: isDark,
                chartBg: colors.card,
                labels: chartYears.map((e) => e.toString()).toList(),
                values: chartValues,
                legend1: "Total Returns",
                barColor: Colors.blueAccent,
                barWidth: 20,
              ),
              Divider(color: colors.divider),
              const SizedBox(height: 12),
              SectionTitle(title: "Monthly Returns (₹)", isDark: isDark),
              const SizedBox(height: 12),

              CommonBarChart(
                isDark: isDark,
                chartBg: colors.card,
                labels: monthlyChartLabels,
                values: monthlyChartValuesReceived,
                values2: monthlyChartValues,
                legend1: "Total Amount",
                legend2: "Amount Received",
                barColor2: Colors.blue,
                barColor: Colors.green,
                barWidth: 8,
              ),
              const SizedBox(height: 16),
              Divider(color: colors.divider),
              SectionTitle(title: "Returns Summary , $currentYear", isDark: isDark),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InfoCard(
                          icon: Icons.account_balance,
                          iconColor: Colors.blueAccent,
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          label: "Total",
                          value: NumberUtils.formatIndianNumber(totalReturns),
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.currency_rupee,
                          iconColor: Colors.orange,
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          label: "Received",
                          value: NumberUtils.formatIndianNumber(receivedAmount),
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.balance,
                          iconColor: Colors.redAccent,
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                          label: "Balance",
                          value: NumberUtils.formatIndianNumber(balanceAmount),
                          textColor: colors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoCard(
                          icon: Icons.landscape,
                          iconColor: Colors.green,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          label: "Acres",
                          value: NumberUtils.formatIndianNumber(totalAreaWorked),
                          textColor: colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: _openSortSheet,
                        icon: Icon(sortIcon),
                        color: colors.text,
                        tooltip: "Sort",
                      ),
                      IconButton(
                        onPressed: _openFilterSheet,
                        icon: const Icon(Icons.filter_list),
                        color: colors.text,
                      ),
                    ],
                  )

                ],
              ),
              const SizedBox(height: 12),
              _buildStatusTabs(colors),
              const SizedBox(height: 12),

              _buildReturnsList(colors),
              const SizedBox(height: 150),
            ],
          ),
        ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "viewClients",
            backgroundColor: Colors.blueGrey,
            onPressed: () {
              Navigator.of(context).push(
                SlideFromRightRoute(
                  page: const ViewClientsPage(),
                ),
              );
            },
            child: const Icon(Icons.people, color: Colors.white),
          ),
          const SizedBox(height: 12),

          FloatingActionButton(
            heroTag: "addReturn",
            backgroundColor: Colors.green,
            onPressed: () {
              Navigator.of(context).push(
                SlideFromRightRoute(
                  page: const AddReturnPage(),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ReturnListItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Color textColor;
  final Color cardColor;
  final Color dividerColor;

  const _ReturnListItem({
    required this.activity,
    required this.textColor,
    required this.cardColor,
    required this.dividerColor,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case "PENDING":
        return Colors.redAccent;
      case "PARTIALLY_PAID":
        return Colors.orange;
      case "PAID":
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = activity["paymentStatus"] ?? "";
    final statusColor = _getStatusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!context.mounted) return;
          Navigator.of(context).push(
            SlideFromRightRoute(
              page: PaymentDetailsPage(
                activityId: activity["id"] ?? 0,
                title: activity["clientName"] ?? "Unknown",
                totalAmount: (activity["amountEarned"] ?? 0).toDouble(),
                amountReceived: (activity["amountPaid"] ?? 0).toDouble(),
                date: activity["activityDate"] ?? "",
                acres: (activity["acresWorked"] ?? 0).toDouble(),
              ),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dividerColor.withOpacity(0.2),
                  width: 0.5,
                ),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // MAIN CONTENT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CLIENT NAME
                        Text(
                          activity["clientName"] ?? "Unknown Client",
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // DATE + ACRES
                        Text(
                          "${activity["activityDate"]} • ${activity["acresWorked"]} Acres",
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // AMOUNT & STATUS
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${NumberUtils.formatIndianNumber(
                            activity["amountEarned"] ?? 0)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          // STATUS DOT
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            status.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // DIVIDER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Divider(
                color: dividerColor.withOpacity(0.4),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  String monthName(int m) {
  const list = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  return list[m - 1];
}

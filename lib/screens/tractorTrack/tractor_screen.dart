import 'package:farmabook/screens/dashboard/investments_screen.dart';
import 'package:flutter/material.dart';
import '../../widgets/frosted_card.dart';
import 'tractor_summary_screen.dart';
import 'tractor_expenses_screen.dart';
import 'tractor_returns_screen.dart';
import 'tractor_details_screen.dart';

class TractorScreen extends StatefulWidget {
  const TractorScreen({Key? key}) : super(key: key);

  @override
  State<TractorScreen> createState() => _TractorScreenState();
}

class _TractorScreenState extends State<TractorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> tractors = [
    {'name': "Tractor 1", 'expenses': 20000.0, 'returns': 30000.0},
    {'name': "Tractor 2", 'expenses': 15000.0, 'returns': 18000.0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color secondaryText =
    isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color accent =
    isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;
    final Color cardGradientStart =
    isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);
    final Color cardGradientEnd =
    isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);
    final Color cardBorder =
    isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

    final double totalExpenses =
    tractors.fold(0.0, (sum, t) => sum + (t['expenses'] as double));
    final double totalReturns =
    tractors.fold(0.0, (sum, t) => sum + (t['returns'] as double));
    final double profit = totalReturns - totalExpenses;
    final double profitPercentage =
    totalExpenses > 0 ? (profit / totalExpenses) * 100 : 0;

    final cardData = [
      {
        'title': 'Total Expenses',
        'value': "₹${totalExpenses.toStringAsFixed(2)}",
        'color': Colors.red,
        'icon': Icons.money_off,
      },
      {
        'title': 'Total Returns',
        'value': "₹${totalReturns.toStringAsFixed(2)}",
        'color': Colors.green,
        'icon': Icons.attach_money,
      },
      {
        'title': 'Profit',
        'value': "₹${profit.toStringAsFixed(2)}",
        'color': profit >= 0 ? Colors.green : Colors.red,
        'icon': Icons.trending_up,
      },
      {
        'title': 'Profit %',
        'value': "${profitPercentage.toStringAsFixed(1)}%",
        'color': profitPercentage >= 0 ? Colors.green : Colors.red,
        'icon': Icons.percent,
      },
    ];

    return SafeArea(
      child: Container(
        color: scaffoldBg,
        child: Column(
          children: [
            const SizedBox(height: 8),

            // --- Compact Top Summary Cards ---
            SizedBox(
              height: 70, // reduced height (was 80)
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: cardData.length,
                itemBuilder: (context, index) {
                  final item = cardData[index];
                  return Container(
                    width: 140, // slightly narrower too
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          (item['color'] as Color).withOpacity(0.08),
                          (item['color'] as Color).withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: (item['color'] as Color).withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (item['color'] as Color).withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryText,
                                  fontWeight: FontWeight.w500,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item['value'] as String,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: item['color'] as Color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: accent,
              isScrollable: true,
              unselectedLabelColor: secondaryText,
              indicatorColor: accent,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: "Summary"),
                Tab(text: "Expenses"),
                Tab(text: "Returns"),
                Tab(text: "Tractor"),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  TractorSummaryScreen(tractors: tractors),
                  TractorExpensesScreen(tractors: tractors),
                  TractorReturnsScreen(tractors: tractors),
                  TractorDetailsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

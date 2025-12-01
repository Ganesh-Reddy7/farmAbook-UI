import 'package:flutter/material.dart';
// Note: FrostedCard is no longer imported as the custom card widget is used directly.
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

  // Helper function to build the summary card widget
  Widget _buildSummaryCard(Map<String, dynamic> item, Color secondaryText) {
    final Color itemColor = item['color'] as Color;

    // Height is managed by the parent container (SizedBox or GridView)
    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            itemColor.withOpacity(0.08),
            itemColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: itemColor.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: itemColor.withOpacity(0.04),
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
              color: itemColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'] as IconData,
              color: itemColor,
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
                    color: itemColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color secondaryText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color accent = isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;
    // Unused color variables removed for clarity: cardGradientStart, cardGradientEnd, cardBorder

    final double totalExpenses = tractors.fold(0.0, (sum, t) => sum + (t['expenses'] as double));
    final double totalReturns = tractors.fold(0.0, (sum, t) => sum + (t['returns'] as double));
    final double profit = totalReturns - totalExpenses;
    final double profitPercentage = totalExpenses > 0 ? (profit / totalExpenses) * 100 : 0;

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

            // --- RESPONSIVE Summary Cards Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double breakpoint = 600;
                  final bool isWideScreen = constraints.maxWidth > breakpoint;

                  if (isWideScreen) {
                    // Wide Screen: Use GridView to fill the width
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cardData.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4 cards per row
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        // Aspect ratio for a card height of 70px on a wide screen
                        childAspectRatio: 2.5,
                      ),
                      itemBuilder: (context, index) {
                        return _buildSummaryCard(cardData[index], secondaryText);
                      },
                    );
                  } else {
                    // Small Screen: Use horizontal ListView (original design)
                    return SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemCount: cardData.length,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 140, // Fixed width for horizontal scrolling
                            child: _buildSummaryCard(cardData[index], secondaryText),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // --- RESPONSIVE Tabs Section ---
            LayoutBuilder(
                builder: (context, constraints) {
                  const double breakpoint = 250;
                  final bool isWideScreen = constraints.maxWidth > breakpoint;

                  return TabBar(
                    controller: _tabController,
                    labelColor: accent,
                    isScrollable: !isWideScreen,
                    unselectedLabelColor: secondaryText,
                    indicatorColor: accent,
                    tabAlignment: isWideScreen ? TabAlignment.fill : TabAlignment.start,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                    tabs: const [
                      Tab(text: "Summary"),
                      Tab(text: "Expenses"),
                      Tab(text: "Returns"),
                      Tab(text: "Tractor"),
                    ],
                  );
                }
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  TractorSummaryScreen(tractors: tractors),
                  TractorExpensesScreen(),
                  TractorReturnsScreen(),
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
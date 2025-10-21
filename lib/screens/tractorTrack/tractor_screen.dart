import 'package:flutter/material.dart';
import 'dart:ui';
import '../../widgets/frosted_card.dart'; // FrostedCardResponsive

class TractorScreen extends StatefulWidget {
  const TractorScreen({Key? key}) : super(key: key);

  @override
  State<TractorScreen> createState() => _TractorScreenState();
}

class _TractorScreenState extends State<TractorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Sample tractor data (multiple tractors)
  final List<Map<String, dynamic>> tractors = [
    {'name': "Tractor 1", 'expenses': 20000.0, 'returns': 30000.0},
    {'name': "Tractor 2", 'expenses': 15000.0, 'returns': 18000.0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final Color primaryText = isDark ? Colors.white : Colors.black87;
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

    // Aggregate totals
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

            // Responsive Top Cards (Totals)
            SizedBox(
              height: 90,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int cardsPerScreen =
                  cardData.length >= 2 ? 2 : cardData.length;
                  double cardWidth = (constraints.maxWidth -
                      ((cardsPerScreen + 1) * 16)) /
                      cardsPerScreen;

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemCount: cardData.length,
                    itemBuilder: (context, index) {
                      final item = cardData[index];
                      return SizedBox(
                        width: cardWidth,
                        child: FrostedCardResponsive(
                          title: item['title'] as String,
                          value: item['value'] as String,
                          primaryText: item['color'] as Color,
                          secondaryText: secondaryText,
                          gradientStart: cardGradientStart,
                          gradientEnd: cardGradientEnd,
                          borderColor: cardBorder,
                          leadingIcon: item['icon'] as IconData,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: accent,
              unselectedLabelColor: secondaryText,
              indicatorColor: accent,
              tabs: const [
                Tab(text: "Summary"),
                Tab(text: "Expenses"),
                Tab(text: "Returns"),
                Tab(text: "Tractor"),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(primaryText),
                  _buildExpensesTab(primaryText),
                  _buildReturnsTab(primaryText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(Color textColor) {
    return Center(
      child: Text(
        "Tractor Summary (all tractors)",
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildExpensesTab(Color textColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tractors.length,
      itemBuilder: (context, index) {
        final t = tractors[index];
        return ListTile(
          title: Text(
            t['name'],
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
          ),
          subtitle: Text("Expenses: ₹${t['expenses']}"),
        );
      },
    );
  }

  Widget _buildReturnsTab(Color textColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tractors.length,
      itemBuilder: (context, index) {
        final t = tractors[index];
        return ListTile(
          title: Text(
            t['name'],
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
          ),
          subtitle: Text("Returns: ₹${t['returns']}"),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../../widgets/frosted_card.dart';
import 'summary_screen.dart';
import 'lent_screen.dart';
import 'debt_screen.dart';
import 'maturity_bonds_screen.dart';

class LoanManagementScreen extends StatefulWidget {
  const LoanManagementScreen({Key? key}) : super(key: key);

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, double> cardValues = {
    "Total Debt": 50000,
    "Total Lent": 30000,
    "Interest to be Paid": 2000,
    "Interest to be Received": 1500,
  };

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

    final cardData = cardValues.entries.map((e) {
      Color color;
      IconData icon;
      if (e.key.contains("Debt")) {
        color = Colors.red;
        icon = Icons.money_off;
      } else if (e.key.contains("Interest to be Paid")) {
        color = Colors.orange;
        icon = Icons.payment;
      } else {
        color = Colors.green;
        icon = Icons.savings;
      }
      return {
        "title": e.key,
        "value": "₹${e.value.toStringAsFixed(2)}",
        "color": color,
        "icon": icon,
      };
    }).toList();

    return SafeArea(
      child: Container(
        color: scaffoldBg,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Compact but Wider Summary Cards
            SizedBox(
              height: 70, // reduced height
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemCount: cardData.length,
                itemBuilder: (context, index) {
                  final item = cardData[index];
                  return SizedBox(
                    width: 190,
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
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: accent,
              isScrollable: true,
              unselectedLabelColor: secondaryText,
              indicatorColor: accent,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: "Summary"),
                Tab(text: "Lent"),
                Tab(text: "Debt"),
                Tab(text: "Maturity Bonds"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SummaryScreen(
                    onSeeAllLent: () => _tabController.animateTo(1),
                    onSeeAllDebt: () => _tabController.animateTo(2),
                    onSeeAllMaturity: () => _tabController.animateTo(3),
                  ),
                  LentScreen(),
                  DebtScreen(),
                  MaturityBondsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

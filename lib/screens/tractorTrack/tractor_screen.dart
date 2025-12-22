import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/frosted_card.dart';
import 'tractor_summary_screen.dart';
import 'tractor_expenses_screen.dart';
import 'tractor_returns_screen.dart';
import 'tractor_details_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/tractor_providers.dart';

class TractorScreen extends ConsumerStatefulWidget {
  const TractorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TractorScreen> createState() => _TractorScreenState();
}

class _TractorScreenState extends ConsumerState<TractorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
    final colors = AppColors.fromTheme(isDark);
    final statsAsync = ref.watch(tractorStatsProvider(2025));
    return SafeArea(
      child: Container(
        color: colors.card,
        child: Column(
          children: [
            // const SizedBox(height: 8),
            statsAsync.when(
              loading: () => const SizedBox(
                height: 70,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SizedBox(
                height: 70,
                child: Center(
                  child: Text(
                    "Error loading stats",
                    style: TextStyle(color: colors.secondaryText),
                  ),
                ),
              ),

              data: (stats) {
                final double totalExpenses = stats.totalExpenses;
                final double totalReturns = stats.totalReturns;
                final double profit = totalReturns - totalExpenses;
                final double profitPercentage =
                totalExpenses > 0 ? (profit / totalExpenses) * 100 : 0;
                // Card Data
                final cardData = [
                  {
                    'title': 'Total Expenses',
                    'value': "₹${totalExpenses.toStringAsFixed(0)}",
                    'color': Colors.red,
                    'icon': Icons.money_off,
                  },
                  {
                    'title': 'Total Returns',
                    'value': "₹${totalReturns.toStringAsFixed(0)}",
                    'color': Colors.green,
                    'icon': Icons.attach_money,
                  },
                  {
                    'title': 'Profit',
                    'value': "₹${profit.toStringAsFixed(0)}",
                    'color': profit >= 0 ? Colors.green : Colors.red,
                    'icon': Icons.trending_up,
                  },
                  {
                    'title': 'Profit %',
                    'value': "${profitPercentage.toStringAsFixed(1)}%",
                    'color': profitPercentage >= 0 ? Colors.green : Colors.red,
                    'icon': Icons.percent,
                  },
                  {
                    'title': 'Fuel Used (L)',
                    'value': "${stats.fuelLitres.toStringAsFixed(1)} L",
                    'color': Colors.orange,
                    'icon': Icons.local_gas_station,
                  },
                  {
                    'title': 'Acres Worked',
                    'value': "${stats.acresWorked.toStringAsFixed(1)} acres",
                    'color': Colors.blue,
                    'icon': Icons.landscape,
                  },
                ];
                return SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemCount: cardData.length,
                    itemBuilder: (context, index) {
                      final item = cardData[index];
                      final Color shadeColor =
                      (item['color'] as Color).withOpacity(isDark ? 0.15 : 0.10);

                      return SizedBox(
                        width: 190,
                        child: FrostedCardResponsive(
                          title: item['title'] as String,
                          value: item['value'] as String,
                          primaryText: item['color'] as Color,
                          secondaryText: colors.secondaryText,
                          gradientStart: shadeColor,
                          gradientEnd: shadeColor.withOpacity(0.03),
                          borderColor: colors.border,
                          leadingIcon: item['icon'] as IconData,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // -------- TABS --------
            LayoutBuilder(builder: (context, constraints) {
              const double breakpoint = 250;
              final bool isWideScreen = constraints.maxWidth > breakpoint;

              return TabBar(
                controller: _tabController,
                labelColor: colors.accent,
                unselectedLabelColor: colors.secondaryText,
                indicatorColor: colors.accent,
                isScrollable: !isWideScreen,
                tabAlignment:
                isWideScreen ? TabAlignment.fill : TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                tabs: const [
                  Tab(text: "Summary"),
                  Tab(text: "Expenses"),
                  Tab(text: "Returns"),
                  Tab(text: "Tractor"),
                ],
              );
            }),
            // -------- TAB CONTENT --------
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  TractorSummaryScreen(),
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

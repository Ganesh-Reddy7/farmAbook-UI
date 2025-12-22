import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/reports_service.dart';
import '../theme/app_colors.dart';
import '../widgets/frosted_card.dart';
import 'dashboard/summary_screen.dart';
import 'dashboard/investments_screen.dart';
import 'dashboard/returns_screen.dart';
import 'dashboard/crop_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final User? user;

  const DashboardScreen({required this.onToggleTheme, this.user, Key? key})
      : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _reportData;
  late TabController _tabController;
  final NumberFormat _formatter = NumberFormat("#,##,###");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReports();
  }

  void _loadReports() async {
    if (widget.user != null) {
      int year = _getFinancialYear();
      Map<String, dynamic>? data = await ReportsService().getReports(farmer: widget.user!, year: year);
      setState(() => _reportData = data);
    }
  }

  int _getFinancialYear() {
    DateTime now = DateTime.now();
    return now.month >= 5 ? now.year : now.year - 1;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    final double profitOrLoss = (_reportData?['profitOrLoss'] ?? 0).toDouble();
    final double totalInvestment = (_reportData?['totalInvestment'] ?? 0).toDouble();
    final double totalReturns = (_reportData?['totalReturns'] ?? 0).toDouble();
    final double profitLossPercentage = totalInvestment > 0 ? (profitOrLoss / totalInvestment) * 100 : 0;
    final Color profitLossColor = profitOrLoss >= 0 ? Colors.green : Colors.red;

    final cardData = [
      {
        'title': 'Profit/Loss',
        'value': "₹${_formatter.format(profitOrLoss)}",
        'color': profitLossColor,
        'icon': Icons.trending_up,
      },
      {
        'title': 'Investments',
        'value': "₹${_formatter.format(totalInvestment)}",
        'color': Colors.orange,
        'icon': Icons.account_balance_wallet,
      },
      {
        'title': 'Returns',
        'value': "₹${_formatter.format(totalReturns)}",
        'color': Colors.blue,
        'icon': Icons.attach_money,
      },
      {
        'title': 'Profit/Loss %',
        'value': "${profitLossPercentage.toStringAsFixed(1)}%",
        'color': profitLossPercentage >= 0 ? Colors.green : Colors.red,
        'icon': Icons.percent,
      },
    ];

    return Column(
      children: [
        // const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cardData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = cardData[index];
              final Color shadeColor = (item['color'] as Color).withOpacity(isDark ? 0.15 : 0.10);
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
        ),
        // const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: colors.accent,
          unselectedLabelColor: colors.secondaryText,
          indicatorColor: colors.accent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0),

          tabs: const [
            Tab(text: "Summary"),
            Tab(text: "Investments"),
            Tab(text: "Returns"),
            Tab(text: "Crops"),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SummaryScreen(),
              InvestmentsScreen(
                onDataChanged: _loadReports,
              ),
              ReturnsScreen(
                onDataChanged: _loadReports,
              ),
              CropsScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

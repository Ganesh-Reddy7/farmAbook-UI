import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/reports_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReports();
  }

  void _loadReports() async {
    if (widget.user != null) {
      int year = _getFinancialYear();
      Map<String, dynamic>? data =
      await ReportsService().getReports(farmer: widget.user!, year: year);
      setState(() => _reportData = data);
    }
  }

  int _getFinancialYear() {
    DateTime now = DateTime.now();
    return now.month >= 5 ? now.year : now.year - 1;
  }

  void _refreshReports() async {
    if (widget.user != null) {
      int year = _getFinancialYear();
      Map<String, dynamic>? data = await ReportsService().getReports(
        farmer: widget.user!,
        year: year,
      );
      setState(() {
        _reportData = data;
      });
    }
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

    final double profitOrLoss = (_reportData?['profitOrLoss'] ?? 0).toDouble();
    final double totalInvestment =
    (_reportData?['totalInvestment'] ?? 0).toDouble();
    final double totalReturns =
    (_reportData?['totalReturns'] ?? 0).toDouble();
    final double profitLossPercentage =
    totalInvestment > 0 ? (profitOrLoss / totalInvestment) * 100 : 0;
    final Color profitLossColor =
    profitOrLoss >= 0 ? Colors.green : Colors.red;

    final cardData = [
      {
        'title': 'Profit/Loss',
        'value': "₹${profitOrLoss.toStringAsFixed(2)}",
        'color': profitLossColor,
        'icon': Icons.trending_up,
      },
      {
        'title': 'Investments',
        'value': "₹${totalInvestment.toStringAsFixed(2)}",
        'color': accent,
        'icon': Icons.account_balance_wallet,
      },
      {
        'title': 'Returns',
        'value': "₹${totalReturns.toStringAsFixed(2)}",
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
        // Top cards
        const SizedBox(height: 8),
        SizedBox(
          height: 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cardData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final item = cardData[index];
              return FrostedCardResponsive(
                title: item['title'] as String,
                value: item['value'] as String,
                primaryText: item['color'] as Color,
                secondaryText: secondaryText,
                gradientStart: cardGradientStart,
                gradientEnd: cardGradientEnd,
                borderColor: cardBorder,
                leadingIcon: item['icon'] as IconData, // ✅ added icon
              );
            },
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: accent,
          unselectedLabelColor: secondaryText,
          indicatorColor: accent,
          tabAlignment: TabAlignment.start,
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
              SummaryScreen(
                accent: accent,
                primaryText: primaryText,
                secondaryText: secondaryText,
                scaffoldBg: scaffoldBg,
                cardGradientStart: cardGradientStart,
                cardGradientEnd: cardGradientEnd,
                cardBorder: cardBorder,
              ),
              InvestmentsScreen(
                accent: accent,
                primaryText: primaryText,
                secondaryText: secondaryText,
                scaffoldBg: scaffoldBg,
                cardGradientStart: cardGradientStart,
                cardGradientEnd: cardGradientEnd,
                cardBorder: cardBorder,
                onDataChanged: _refreshReports,
              ),
              ReturnsScreen(
                accent: accent,
                primaryText: primaryText,
                secondaryText: secondaryText,
                scaffoldBg: scaffoldBg,
                cardGradientStart: cardGradientStart,
                cardGradientEnd: cardGradientEnd,
                cardBorder: cardBorder,
                onDataChanged: _refreshReports,
              ),
              CropsScreen(
                accent: accent,
                primaryText: primaryText,
                secondaryText: secondaryText,
                scaffoldBg: scaffoldBg,
                cardGradientStart: cardGradientStart,
                cardGradientEnd: cardGradientEnd,
                cardBorder: cardBorder,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

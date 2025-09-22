import 'package:flutter/material.dart';
import 'dart:ui';
import 'dashboard/summary_screen.dart';
import 'dashboard/investments_screen.dart';
import 'dashboard/returns_screen.dart';
import '../widgets/frosted_card.dart'; // Your FrostedCardResponsive widget
import '../models/user.dart';
import '../services/session_service.dart';
import '../services/reports_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  DashboardScreen({required this.onToggleTheme});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  User? _user; // User info
  Map<String, dynamic>? _reportData;
  late TabController _tabController;

  final List<Map<String, String>> cardData = [
    {'title': 'PROFIT/LOSS', 'value': '₹12,500'},
    {'title': 'INVESTMENTS', 'value': '₹75,000'},
    {'title': 'RETURNS', 'value': '₹8,200'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUserAndReports();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUser() async {
    User? user = await SessionService().getUser();
    setState(() {
      _user = user;
    });
  }

  void _loadUserAndReports() async {
    User? user = await SessionService().getUser();
    setState(() => _user = user);

    if (user != null) {
      int year = _getFinancialYear();
      Map<String, dynamic>? data = await ReportsService().getReports(farmer: user, year: year);
      if (data != null) {
        setState(() => _reportData = data);
      }
    }
  }

  /// Returns the financial year based on May-April
  int _getFinancialYear() {
    DateTime now = DateTime.now();
    if (now.month >= 5) {
      // May to Dec -> current year
      return now.year;
    } else {
      // Jan to April -> previous year
      return now.year - 1;
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;

    // Theme-aware colors
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color accent = isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;
    final Color cardGradientStart = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);
    final Color cardGradientEnd = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);
    final Color cardBorder = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

    final cardData = [
      {'title': 'Profit/Loss', 'value': _reportData?['profitOrLoss']?.toString() ?? '₹0'},
      {'title': 'Investments', 'value': _reportData?['totalInvestment']?.toString() ?? '₹0'},
      {'title': 'Returns', 'value': _reportData?['totalReturns']?.toString() ?? '₹0'},
      {'title': 'Profit/Loss Percentage', 'value': _reportData?['totalReturns']?.toString() ?? '₹0'},
    ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.eco, color: scaffoldBg, size: 22),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "FarmAbook",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Welcome back${_user != null ? ', ${_user!.username}' : ''}!",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryText,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right-side icons
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.brightness_6, color: primaryText.withOpacity(0.9)),
                        onPressed: widget.onToggleTheme,
                      ),
                      IconButton(
                        icon: Icon(Icons.person, color: primaryText.withOpacity(0.9)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// Top Cards
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cardData.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final item = cardData[index];
                  return FrostedCardResponsive(
                    title: item['title']!,
                    value: item['value']!,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    gradientStart: cardGradientStart,
                    gradientEnd: cardGradientEnd,
                    borderColor: cardBorder,
                  );
                },
              ),
            ),

            /// Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: accent,
              unselectedLabelColor: secondaryText,
              indicatorColor: accent,
              tabs: const [
                Tab(text: "Summary"),
                Tab(text: "Investments"),
                Tab(text: "Returns"),
              ],
            ),

            /// Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SummaryScreen( accent: accent,
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
                  ),
                  ReturnsScreen( accent: accent,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    scaffoldBg: scaffoldBg,
                    cardGradientStart: cardGradientStart,
                    cardGradientEnd: cardGradientEnd,
                    cardBorder: cardBorder,),
                ],
              ),
            ),
          ],
        ),
      ),

      /// Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: scaffoldBg,
        selectedItemColor: accent,
        unselectedItemColor: secondaryText,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Summary"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Add Investment"),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Add Return"),
        ],
      ),
    );
  }
}

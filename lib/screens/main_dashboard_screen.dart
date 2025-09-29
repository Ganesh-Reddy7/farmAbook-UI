import 'package:flutter/material.dart';

import 'dashboard_screen.dart'; // import your existing screen

class MainDashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainDashboardScreen({required this.onToggleTheme, Key? key}) : super(key: key);

  @override
  _MainDashboardScreenState createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardTab(onToggleTheme: widget.onToggleTheme),
      LoanManagementScreen(),
      TractorScreen(),
    ];
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color accent = isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;
    final Color secondaryText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: scaffoldBg,
        selectedItemColor: accent,
        unselectedItemColor: secondaryText,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: "Summary"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: "Loan Management"),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: "Tractor"),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const DashboardTab({required this.onToggleTheme, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(onToggleTheme: onToggleTheme);
  }
}

class LoanManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(
          "Loan Management Screen",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ));
  }
}

class TractorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(
          "Tractor Screen",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ));
  }
}

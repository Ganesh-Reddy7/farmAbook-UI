import 'package:farmabook/screens/userProfile/profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/session_service.dart';
import 'dashboard_screen.dart';
import 'loanManagement/loan_management_screen.dart';
import 'tractorTrack/tractor_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainDashboardScreen({required this.onToggleTheme, Key? key}) : super(key: key);

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedIndex = 0;
  User? _user;
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    User? user = await SessionService().getUser();
    setState(() {
      _user = user;
      _screens = [
        DashboardScreen(onToggleTheme: widget.onToggleTheme, user: _user),
        const LoanManagementScreen(),
        const TractorScreen(),
      ];
    });
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _navigateToProfile() {
    if (_user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          user: _user,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color accent = isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.brightness_6, color: primaryText.withOpacity(0.9)),
                        onPressed: widget.onToggleTheme,
                      ),
                      IconButton(
                        icon: Icon(Icons.person, color: primaryText.withOpacity(0.9)),
                        onPressed: _navigateToProfile,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _screens.isNotEmpty ? _screens[_selectedIndex] : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: scaffoldBg,
        selectedItemColor: accent,
        unselectedItemColor: secondaryText,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: "Loan Management"),
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: "Tractor"),
        ],
      ),
    );
  }
}

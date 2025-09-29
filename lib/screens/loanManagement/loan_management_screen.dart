import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts
import '../../widgets/frosted_card.dart';

class LoanManagementScreen extends StatefulWidget {
  const LoanManagementScreen({Key? key}) : super(key: key);

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Sample data
  final Map<String, double> cardValues = {
    "Total Debt": 50000,
    "Total Lent": 30000,
    "Interest to be Paid": 2000,
    "Interest to be Received": 1500,
  };

  // Sample table data
  final List<Map<String, dynamic>> lentLoans = [
    {"borrower": "John", "amount": 10000, "interest": 5, "status": "Active"},
    {"borrower": "Alice", "amount": 15000, "interest": 6, "status": "Repaid"},
    {"borrower": "Bob", "amount": 5000, "interest": 4, "status": "Active"},
  ];

  final List<Map<String, dynamic>> debts = [
    {"lender": "Bank A", "amount": 20000, "interest": 7, "status": "Active"},
    {"lender": "Bank B", "amount": 30000, "interest": 6, "status": "Overdue"},
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
    final Color accent = isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;
    final Color cardGradientStart = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);
    final Color cardGradientEnd = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);
    final Color cardBorder = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

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
        "gradientStart": cardGradientStart,
        "gradientEnd": cardGradientEnd,
        "borderColor": cardBorder,
      };
    }).toList();

    return SafeArea(
      child: Container(
        color: scaffoldBg,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cards
            SizedBox(
              height: 85,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemCount: cardData.length,
                itemBuilder: (context, index) {
                  final item = cardData[index];
                  return SizedBox(
                    width: 180,
                    child: FrostedCardResponsive(
                      title: item['title'] as String,
                      value: item['value'] as String,
                      primaryText: item['color'] as Color,
                      secondaryText: secondaryText,
                      gradientStart: cardGradientStart,
                      gradientEnd: cardGradientEnd,
                      borderColor: cardBorder,
                      leadingIcon: Icons.account_balance, // example icon
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: accent,
              unselectedLabelColor: secondaryText,
              indicatorColor: accent,
              tabs: const [
                Tab(text: "Summary"),
                Tab(text: "Lent"),
                Tab(text: "Debt"),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(primaryText, accent),
                  _buildLentTab(primaryText, accent),
                  _buildDebtTab(primaryText, accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Tab Widgets ----------------
  Widget _buildSummaryTab(Color textColor, Color accent) {
    double totalDebt = cardValues["Total Debt"]!;
    double totalLent = cardValues["Total Lent"]!;
    double interestPaid = cardValues["Interest to be Paid"]!;
    double interestReceived = cardValues["Interest to be Received"]!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Pie Chart for Debt vs Lent
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: totalDebt,
                    color: Colors.red,
                    title: 'Debt',
                    radius: 60,
                    titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: totalLent,
                    color: Colors.green,
                    title: 'Lent',
                    radius: 60,
                    titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: interestPaid + interestReceived,
                    color: Colors.orange,
                    title: 'Interest',
                    radius: 60,
                    titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text("Overview of Loans and Interest", style: TextStyle(color: textColor, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLentTab(Color textColor, Color accent) {
    final List<Map<String, dynamic>> lentLoans = [
      {"borrower": "John", "amount": 10000, "interest": 5, "status": "Active"},
      {"borrower": "Alice", "amount": 15000, "interest": 6, "status": "Repaid"},
      {"borrower": "Bob", "amount": 5000, "interest": 4, "status": "Active"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lentLoans.length,
      itemBuilder: (context, index) {
        final loan = lentLoans[index];
        return Card(
          color: loan['status'] == 'Active' ? Colors.green.shade50 : Colors.grey.shade200,
          child: ListTile(
            leading: Icon(Icons.person, color: accent),
            title: Text("${loan['borrower']} - ₹${loan['amount']}"),
            subtitle: Text("Interest: ${loan['interest']}% | Status: ${loan['status']}"),
            trailing: loan['status'] == 'Active'
                ? Icon(Icons.check_circle_outline, color: Colors.green)
                : Icon(Icons.done_all, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildDebtTab(Color textColor, Color accent) {
    final List<Map<String, dynamic>> debts = [
      {"lender": "Bank A", "amount": 20000, "interest": 7, "status": "Active"},
      {"lender": "Bank B", "amount": 30000, "interest": 6, "status": "Overdue"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        return Card(
          color: debt['status'] == 'Active' ? Colors.red.shade50 : Colors.red.shade100,
          child: ListTile(
            leading: Icon(Icons.account_balance, color: accent),
            title: Text("${debt['lender']} - ₹${debt['amount']}"),
            subtitle: Text("Interest: ${debt['interest']}% | Status: ${debt['status']}"),
            trailing: debt['status'] == 'Active'
                ? Icon(Icons.pending, color: Colors.orange)
                : Icon(Icons.error, color: Colors.red),
          ),
        );
      },
    );
  }
}

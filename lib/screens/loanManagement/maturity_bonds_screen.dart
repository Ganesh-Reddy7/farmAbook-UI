import 'package:flutter/material.dart';

class MaturityBondsScreen extends StatelessWidget {
  MaturityBondsScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> bonds = [
    {"bondName": "Gov Bond A", "amount": 50000, "maturityDate": "2026-12-31", "interest": 6.5, "status": "Active"},
    {"bondName": "Corp Bond B", "amount": 30000, "maturityDate": "2025-08-15", "interest": 7.2, "status": "Matured"},
    {"bondName": "Gov Bond C", "amount": 40000, "maturityDate": "2027-03-10", "interest": 6.0, "status": "Active"},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;

    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color accent = isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;
    final Color cardGradientStart = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);
    final Color cardGradientEnd = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);
    final Color cardBorder = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bonds.length,
      itemBuilder: (context, index) {
        final bond = bonds[index];
        final bool isActive = bond['status'] == 'Active';

        return Card(
          color: isActive ? Colors.blue.shade50 : Colors.grey.shade200,
          child: ListTile(
            leading: Icon(Icons.account_balance_wallet, color: accent),
            title: Text("${bond['bondName']} - ₹${bond['amount']}", style: TextStyle(color: primaryText)),
            subtitle: Text(
              "Maturity: ${bond['maturityDate']} | Interest: ${bond['interest']}% | Status: ${bond['status']}",
              style: TextStyle(color: secondaryText),
            ),
            trailing: isActive
                ? const Icon(Icons.access_time, color: Colors.blue)
                : const Icon(Icons.check_circle_outline, color: Colors.green),
          ),
        );
      },
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/lentDto.dart';

enum AmountType { actual, updatedPrincipal, returns, total }

class LoanDetailScreen extends StatefulWidget {
  final LentLoanDTO loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  AmountType selectedAmountType = AmountType.actual;

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final Color accent = Colors.greenAccent.shade400;

    double actualAmount = loan.principal ?? 0;
    double updatedAmount = loan.updatedPrincipal ?? 0;
    double returnsAmount = loan.currentInterest ?? 0;
    double totalAmount = (loan.updatedPrincipal ?? 0) + (loan.currentInterest ?? 0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF081712) : Colors.grey[100],
      appBar: AppBar(
        title: Text("Loan Details", style: TextStyle(color: primaryText)),
        backgroundColor: isDark ? const Color(0xFF081712) : Colors.green,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Loan Overview Card ----
          _buildOverviewCard(loan, primaryText, secondaryText, accent, isDark),

          const SizedBox(height: 20),

          // ---- Amount Toggle ----
          _buildAmountToggle(accent, isDark),

          const SizedBox(height: 20),

          // ---- Displayed Amount ----
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  colors: [accent.withOpacity(0.3), accent.withOpacity(0.1)]),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                selectedAmountType == AmountType.actual
                    ? "₹${actualAmount.toStringAsFixed(0)}"
                    : selectedAmountType == AmountType.updatedPrincipal
                    ? "₹${updatedAmount.toStringAsFixed(0)}"
                    : selectedAmountType == AmountType.returns
                    ? "₹${returnsAmount.toStringAsFixed(0)}"
                    : "₹${totalAmount.toStringAsFixed(0)}",
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: accent),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- Maturity Progress ----
          _buildMaturityProgress(loan, accent, secondaryText),

          const SizedBox(height: 20),

          // ---- Loan Details Section ----
          _buildDetailsSection(loan, primaryText, secondaryText, totalAmount),
          const SizedBox(height: 40), // Extra space for buttons

        ],
      ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Close Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB0BEC5), // Soft grey
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black87
                          : Colors.white, // Contrast text
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add Payment Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047), // Fresh green
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implement Add Payment functionality
                    print("Add Payment clicked for ${loan.source}");
                  },
                  child: const Text(
                    "Add Payment",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildOverviewCard(LentLoanDTO loan, Color primaryText, Color secondaryText,
      Color accent, bool isDark) {
    final status = loan.isClosed == true
        ? "Closed"
        : loan.nearMaturity == true
        ? "Near Maturity"
        : "Active";

    Color statusColor;
    switch (status) {
      case "Closed":
        statusColor = Colors.grey;
        break;
      case "Near Maturity":
        statusColor = Colors.orangeAccent;
        break;
      default:
        statusColor = Colors.greenAccent.shade400;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.2),
            ),
            child: Icon(Icons.account_balance_wallet, color: accent, size: 36),
          ),

          const SizedBox(height: 12),

          // Loan/Source Name
          Text(
            loan.source ?? "Unknown",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: primaryText),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Status, Interest & Maturity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Status
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),

              // Interest
              Row(
                children: [
                  Icon(Icons.percent, color: accent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${loan.interestRate?.toStringAsFixed(2) ?? '0'}%",
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                ],
              ),

              // Next Maturity
              Row(
                children: [
                  Icon(Icons.calendar_today, color: accent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    loan.nextMaturityDate ?? "N/A",
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountToggle(Color accent, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: AmountType.values.map((type) {
        final isSelected = type == selectedAmountType;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedAmountType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? accent : isDark ? Colors.white12 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? accent : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  type.name.toUpperCase().replaceAll("UPDATEDPRINCIPAL", "UPDATED"),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : accent),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaturityProgress(LentLoanDTO loan, Color accent, Color secondaryText) {
    final lastCompounded = DateTime.tryParse(loan.lastCompoundedDate ?? '') ?? DateTime.now();
    final nextMaturity = DateTime.tryParse(loan.nextMaturityDate ?? '') ?? DateTime.now();

    // Total months between lastCompoundedDate and nextMaturityDate
    final totalMonths = (nextMaturity.year - lastCompounded.year) * 12 +
        (nextMaturity.month - lastCompounded.month);

    // Months passed since lastCompoundedDate
    final elapsedMonths = (DateTime.now().year - lastCompounded.year) * 12 +
        (DateTime.now().month - lastCompounded.month);

    // Progress ratio (0 to 1)
    final progress = totalMonths > 0
        ? (elapsedMonths / totalMonths).clamp(0.0, 1.0)
        : 1.0;

    // Color coding based on progress
    Color progressColor;
    if (progress < 0.7) {
      progressColor = Colors.green;
    } else if (progress < 0.9) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.redAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Maturity Progress", style: TextStyle(color: secondaryText, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            color: progressColor,
            backgroundColor: Colors.grey.shade300.withOpacity(0.3),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text("${(progress * 100).toStringAsFixed(1)}%", style: TextStyle(color: secondaryText, fontSize: 12)),
      ],
    );
  }


  Widget _buildDetailsSection(
      LentLoanDTO loan, Color primaryText, Color secondaryText, double totalAmount) {
    return Column(
      children: [
        _detailRow("Principal", "₹${loan.principal?.toStringAsFixed(0) ?? '0'}", primaryText, secondaryText),
        _detailRow("Updated Principal", "₹${loan.updatedPrincipal?.toStringAsFixed(0) ?? '0'}", primaryText, secondaryText),
        _detailRow("Interest / Returns", "₹${loan.currentInterest?.toStringAsFixed(0) ?? '0'}", primaryText, secondaryText),
        _detailRow("Total Amount", "₹${totalAmount.toStringAsFixed(0)}", primaryText, secondaryText),
        _detailRow("Start Date", "${loan.startDate ?? 'N/A'}", primaryText, secondaryText),
        _detailRow("End Date", "${loan.endDate ?? 'N/A'}", primaryText, secondaryText),
        _detailRow("Maturity Period (Years)", "${loan.maturityPeriodYears ?? '0'}", primaryText, secondaryText),
        _detailRow("Description", "${loan.description ?? 'N/A'}", primaryText, secondaryText),
      ],
    );
  }

  Widget _detailRow(String label, String value, Color primaryText, Color secondaryText) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: secondaryText, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: primaryText, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

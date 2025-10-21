import 'dart:convert';
import 'dart:developer';
import 'package:farmabook/services/loan_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/PaymentHistoryDTO.dart';
import '../../../models/lentDto.dart';
import 'dart:ui'; // <-- needed for BackdropFilter blur

enum AmountType { actual, updatedPrincipal, returns, total }

class LoanDetailScreen extends StatefulWidget {
  final LentLoanDTO loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}


class _LoanDetailScreenState extends State<LoanDetailScreen> {
  AmountType selectedAmountType = AmountType.actual;
  bool isLoading = false;
  List<PaymentHistoryDTO> _paymentHistory = [];
  bool _loadingPayments = false;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _loadingPayments = true);
    final payments = await LoanService().getPaymentHistory(widget.loan.id!);
    log("GKaaxx :: payments :: $payments");
    setState(() {
      _paymentHistory = payments;
      _loadingPayments = false;
    });
  }

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
          _buildOverviewCard(loan, primaryText, secondaryText, accent, isDark),
          const SizedBox(height: 20),
          _buildAmountToggle(accent, isDark),
          const SizedBox(height: 20),
          _buildAmountDisplay(accent, actualAmount, updatedAmount, returnsAmount, totalAmount),
          const SizedBox(height: 20),
          _buildMaturityProgress(loan, accent, secondaryText),
          const SizedBox(height: 20),
          _buildDetailsSection(loan, primaryText, secondaryText, totalAmount),
          const SizedBox(height: 40),
          _buildPaymentHistorySection(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Close Loan Button
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : _handleCloseLoan,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Close Loan", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            // Add Payment Button
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : _handleAddPayment,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Payment", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ------------------ API Functions ------------------

  Future<void> _handleCloseLoan() async {
    setState(() => isLoading = true);
    final success = await LoanService().closeLoan(widget.loan.id!);
    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Loan closed successfully" : "Failed to close loan")),
    );

    if (success) Navigator.pop(context); // Close screen if successful
  }

  Future<void> _handleAddPayment() async {
    final amountController = TextEditingController();
    DateTime? selectedDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Payment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(selectedDate != null
                        ? "Date: ${selectedDate!.toLocal().toString().split(' ')[0]}"
                        : "Select Payment Date"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isEmpty || selectedDate == null) return;
                Navigator.pop(context, true);
              },
              child: const Text("Add Payment"),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text);
      if (amount != null && selectedDate != null) {
        setState(() => isLoading = true);
        final success = await LoanService().addPayment(widget.loan.id!, amount, selectedDate!);
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? "Payment added successfully" : "Failed to add payment")),
        );
        _fetchPayments(); // refresh list
      }
    }
  }

  /// ------------------ UI Widgets ------------------

  Widget _buildAmountDisplay(Color accent, double actual, double updated, double returns, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [accent.withOpacity(0.3), accent.withOpacity(0.1)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Center(
        child: Text(
          selectedAmountType == AmountType.actual
              ? "₹${actual.toStringAsFixed(0)}"
              : selectedAmountType == AmountType.updatedPrincipal
              ? "₹${updated.toStringAsFixed(0)}"
              : selectedAmountType == AmountType.returns
              ? "₹${returns.toStringAsFixed(0)}"
              : "₹${total.toStringAsFixed(0)}",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accent),
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
    Color statusColor = status == "Closed"
        ? Colors.grey
        : status == "Near Maturity"
        ? Colors.orangeAccent
        : Colors.greenAccent.shade400;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.2)),
            child: Icon(Icons.account_balance_wallet, color: accent, size: 36),
          ),
          const SizedBox(height: 12),
          Text(loan.source ?? "Unknown",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryText),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
              ),
              Row(children: [Icon(Icons.percent, color: accent, size: 16), const SizedBox(width: 4), Text("${loan.interestRate?.toStringAsFixed(2) ?? '0'}%", style: TextStyle(fontSize: 12, color: secondaryText))]),
              Row(children: [Icon(Icons.calendar_today, color: accent, size: 16), const SizedBox(width: 4), Text(loan.nextMaturityDate ?? "N/A", style: TextStyle(fontSize: 12, color: secondaryText))]),
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
                border: Border.all(color: isSelected ? accent : Colors.grey.shade400, width: 1.2),
              ),
              child: Center(
                child: Text(
                  type.name.toUpperCase().replaceAll("UPDATEDPRINCIPAL", "UPDATED"),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : accent),
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
    final totalMonths = (nextMaturity.year - lastCompounded.year) * 12 + (nextMaturity.month - lastCompounded.month);
    final elapsedMonths = (DateTime.now().year - lastCompounded.year) * 12 + (DateTime.now().month - lastCompounded.month);
    final progress = totalMonths > 0 ? (elapsedMonths / totalMonths).clamp(0.0, 1.0) : 1.0;
    Color progressColor = progress < 0.7 ? Colors.green : progress < 0.9 ? Colors.orange : Colors.redAccent;

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

  Widget _buildDetailsSection(LentLoanDTO loan, Color primaryText, Color secondaryText, double totalAmount) {
    Widget _detailRow(String label, String value) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: secondaryText, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: primaryText, fontWeight: FontWeight.bold)),
        ]),
      );
    }

    return Column(
      children: [
        _detailRow("Principal", "₹${loan.principal?.toStringAsFixed(0) ?? '0'}"),
        _detailRow("Updated Principal", "₹${loan.updatedPrincipal?.toStringAsFixed(0) ?? '0'}"),
        _detailRow("Interest / Returns", "₹${loan.currentInterest?.toStringAsFixed(0) ?? '0'}"),
        _detailRow("Total Amount", "₹${totalAmount.toStringAsFixed(0)}"),
        _detailRow("Start Date", "${loan.startDate ?? 'N/A'}"),
        _detailRow("End Date", "${loan.endDate ?? 'N/A'}"),
        _detailRow("Maturity Period (Years)", "${loan.maturityPeriodYears ?? '0'}"),
        _detailRow("Description", "${loan.description ?? 'N/A'}"),
      ],
    );
  }

  Widget _buildPaymentHistorySection() {
    if (_loadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentHistory.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            "Payment History",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ..._paymentHistory.map(
              (p) => Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.greenAccent.withOpacity(0.15),
                  Colors.black.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading Icon with premium glow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.greenAccent.withOpacity(0.8),
                        Colors.greenAccent.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.payments_rounded, color: Colors.black, size: 28),
                ),
                const SizedBox(width: 16),

                // Payment details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "₹${p.amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Principal: ₹${p.principalPaid.toStringAsFixed(2)} | Interest: ₹${p.interestPaid.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    p.paymentDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.greenAccent.shade100,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
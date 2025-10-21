import 'dart:ui';
import 'package:flutter/material.dart';
import 'add_entity/add_lent.dart';
import 'package:farmabook/models/lentDto.dart';
import 'package:farmabook/services/loan_service.dart';

import 'detail_screen/loan_detail_screen.dart';

class LentScreen extends StatefulWidget {
  const LentScreen({Key? key}) : super(key: key);

  @override
  State<LentScreen> createState() => _LentScreenState();
}

enum LoanFilter { active, closed, nearMaturity }
enum LoanSort { amount, interest, maturity }
enum AmountType { actual, updatedPrincipal, returns, total }

class _LentScreenState extends State<LentScreen> {
  List<LentLoanDTO> allLoans = [];
  List<LentLoanDTO> filteredLoans = [];
  LoanFilter selectedFilter = LoanFilter.active;
  LoanSort? selectedSort;
  AmountType selectedAmountType = AmountType.actual;
  String searchQuery = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLentLoans();
  }

  Future<void> fetchLentLoans() async {
    setState(() => isLoading = true);
    allLoans = await LoanService().getLentLoansForFarmer(isGiven: true);
    applyFilter();
    setState(() => isLoading = false);
  }

  void applyFilter() {
    List<LentLoanDTO> temp = [];
    // Filter
    switch (selectedFilter) {
      case LoanFilter.active:
        temp = allLoans.where((loan) => loan.isClosed != true).toList();
        break;
      case LoanFilter.closed:
        temp = allLoans.where((loan) => loan.isClosed == true).toList();
        break;
      case LoanFilter.nearMaturity:
        temp = allLoans.where((loan) => loan.nearMaturity == true).toList();
        break;
    }

    // Search
    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((loan) =>
          (loan.source ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Sort
    if (selectedSort != null) {
      switch (selectedSort!) {
        case LoanSort.amount:
          temp.sort(
                  (a, b) => (b.principal ?? 0).compareTo(a.principal ?? 0));
          break;
        case LoanSort.interest:
          temp.sort((a, b) =>
              (b.currentInterest ?? 0).compareTo(a.currentInterest ?? 0));
          break;
        case LoanSort.maturity:
          temp.sort((a, b) {
            final aDate = a.nextMaturityDate != null
                ? DateTime.tryParse(a.nextMaturityDate!)
                : null;
            final bDate = b.nextMaturityDate != null
                ? DateTime.tryParse(b.nextMaturityDate!)
                : null;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });
          break;
      }
    }

    filteredLoans = temp;
  }

  // Dynamic card values based on toggle
  int get totalLent {
    final activeLoans = allLoans.where((e) => e.isClosed == false).toList();
    switch (selectedAmountType) {
      case AmountType.actual:
        return activeLoans.fold(
          0,
              (sum, e) => sum + (e.remainingPrincipal?.toInt() ?? 0),
        );
      case AmountType.updatedPrincipal:
        return activeLoans.fold(
          0,
              (sum, e) => sum + (e.remainingPrincipal?.toInt() ?? 0),
        );
      case AmountType.returns:
        return activeLoans.fold(
          0,
              (sum, e) => sum + (e.currentInterest?.toInt() ?? 0),
        );
      case AmountType.total:
        return activeLoans.fold(
          0,
              (sum, e) => sum +
              ((e.remainingPrincipal ?? 0).toInt() +
                  (e.currentInterest ?? 0).toInt()),
        );
    }
  }

  int get totalInterest =>
      allLoans.fold(0, (sum, e) => sum + (e.currentInterest?.toInt() ?? 0));
  int get activeCount => allLoans.where((e) => e.isClosed != true).length;
  int get closedCount => allLoans.where((e) => e.isClosed == true).length;
  int get nearMaturityCount =>
      allLoans.where((e) => e.nearMaturity == true).length;

  Future<void> _refreshLoans() async => fetchLentLoans();

  String getAmountLabel() {
    switch (selectedAmountType) {
      case AmountType.actual:
        return "Actual";
      case AmountType.updatedPrincipal:
        return "Updated";
      case AmountType.returns:
        return "Returns";
      case AmountType.total:
        return "Total";
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

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _refreshLoans,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Cards
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildSummaryCard(
                    "Total Lent", "₹$totalLent", Icons.attach_money,
                    accent, primaryText),
                _buildSummaryCard(
                    "Interest", "₹$totalInterest", Icons.percent,
                    Colors.orangeAccent, primaryText),
                _buildSummaryCard(
                    "Active Loans", "$activeCount", Icons.play_arrow,
                    Colors.green, primaryText),
                _buildSummaryCard(
                    "Closed Loans", "$closedCount", Icons.done_all,
                    Colors.grey, primaryText),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton(
                    "Active ($activeCount)",
                    selectedFilter == LoanFilter.active, () {
                  setState(() {
                    selectedFilter = LoanFilter.active;
                    applyFilter();
                  });
                }, Colors.green),
                _buildFilterButton(
                    "Closed ($closedCount)",
                    selectedFilter == LoanFilter.closed, () {
                  setState(() {
                    selectedFilter = LoanFilter.closed;
                    applyFilter();
                  });
                }, Colors.grey),
                _buildFilterButton(
                    "Near Maturity ($nearMaturityCount)",
                    selectedFilter == LoanFilter.nearMaturity, () {
                  setState(() {
                    selectedFilter = LoanFilter.nearMaturity;
                    applyFilter();
                  });
                }, Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by Person',
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white12,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(fontSize: 14, color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    applyFilter();
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sort Button (Left Edge)
                GestureDetector(
                  onTap: () async {
                    final selected = await showModalBottomSheet<LoanSort>(
                      context: context,
                      backgroundColor: Colors.grey[900],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: LoanSort.values.map((sort) {
                          return ListTile(
                            leading: const Icon(Icons.sort, color: Colors.white70),
                            title: Text(
                              selectedSortLabel(sort),
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () => Navigator.pop(context, sort),
                          );
                        }).toList(),
                      ),
                    );
                    if (selected != null) {
                      setState(() {
                        selectedSort = selected;
                        applyFilter();
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sort, color: Colors.white70, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          selectedSort != null ? selectedSortLabel(selectedSort!) : "Sort",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Amount Type Toggle (Right Edge)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final currentIndex =
                      AmountType.values.indexOf(selectedAmountType);
                      final nextIndex =
                          (currentIndex + 1) % AmountType.values.length;
                      selectedAmountType = AmountType.values[nextIndex];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz, color: Colors.white70, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          getAmountLabel(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Loan List
            if (filteredLoans.isEmpty)
              _noDataContainer(scaffoldBg, secondaryText)
            else
              ...filteredLoans.map((loan) =>
                  _buildLoanCard(loan, accent, primaryText, secondaryText)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddLoanScreen(isGiven: true)),
          );
          if (result == true) fetchLentLoans();
        },
        backgroundColor: accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _noDataContainer(Color scaffoldBg, Color secondaryText) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scaffoldBg.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty,
              size: 60, color: secondaryText.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text("No Loans to Display",
              style: TextStyle(
                  color: secondaryText, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("Try changing the filter, search, or add a new loan.",
              style: TextStyle(color: secondaryText.withOpacity(0.8), fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color iconColor, Color textColor) {
    return Container(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [iconColor.withOpacity(0.1), iconColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
      String text, bool selected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : Colors.grey, width: 1),
        ),
        child: Text(text,
            style: TextStyle(color: selected ? color : Colors.white70)),
      ),
    );
  }

  Widget _buildLoanCard(LentLoanDTO loan, Color accent, Color primaryText,
      Color secondaryText) {
    final bool isActive = loan.isClosed != true;
    final bool isNearMaturity = loan.nearMaturity == true;

    double displayAmount;
    switch (selectedAmountType) {
      case AmountType.actual:
        displayAmount = loan.principal ?? 0;
        break;
      case AmountType.updatedPrincipal:
        displayAmount = loan.updatedPrincipal ?? 0;
        break;
      case AmountType.returns:
        displayAmount = loan.currentInterest ?? 0;
        break;
      case AmountType.total:
        displayAmount = (loan.updatedPrincipal ?? 0) +
            (loan.currentInterest ?? 0);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.01)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(Icons.person, color: accent, size: 32),
              title: Text(
                  "${loan.source ?? 'Unknown'} - ₹${displayAmount.toStringAsFixed(0)}",
                  style:
                  TextStyle(color: primaryText, fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "Interest: ${loan.interestRate?.toStringAsFixed(2) ?? '0'}% | Status: ${isActive ? (isNearMaturity ? "Near Maturity" : "Active") : "Closed"}",
                  style: TextStyle(color: secondaryText)),
              trailing: isActive
                  ? Icon(isNearMaturity ? Icons.timelapse : Icons.check_circle_outline,
                  color: isNearMaturity ? Colors.purple : accent)
                  : const Icon(Icons.done_all, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoanDetailScreen(loan: loan),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String selectedSortLabel(LoanSort sort) {
    switch (sort) {
      case LoanSort.amount:
        return "Amount";
      case LoanSort.interest:
        return "Interest";
      case LoanSort.maturity:
        return "Maturity";
    }
  }
}

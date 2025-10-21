import 'dart:ui';
import 'package:farmabook/screens/loanManagement/detail_screen/loan_detail_screen.dart';
import 'package:farmabook/services/loan_service.dart';
import 'package:flutter/material.dart';
import '../../models/lentDto.dart';

class MaturityBondsScreen extends StatefulWidget {
  const MaturityBondsScreen({Key? key}) : super(key: key);

  @override
  State<MaturityBondsScreen> createState() => _MaturityBondsScreenState();
}

enum BondSort { amount, interest, maturity }
enum BondFilter { all, lent, debt }

class _MaturityBondsScreenState extends State<MaturityBondsScreen> {
  List<LentLoanDTO> allBonds = [];
  List<LentLoanDTO> filteredBonds = [];
  BondSort? selectedSort;
  BondFilter selectedFilter = BondFilter.all;
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNearMatureBonds();
  }

  Future<void> fetchNearMatureBonds() async {
    setState(() => isLoading = true);
    try {
      final loans = await LoanService().getLoansForFarmer();
      setState(() {
        allBonds = loans.where((bond) => bond.nearMaturity == true && bond.isClosed == false).toList();
        applyFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching near mature bonds: $e");
    }
  }

  void applyFilter() {
    List<LentLoanDTO> temp = [...allBonds];

    // Filter by Lent/Debt
    if (selectedFilter == BondFilter.lent) {
      temp = temp.where((bond) => bond.isGiven == true).toList();
    } else if (selectedFilter == BondFilter.debt) {
      temp = temp.where((bond) => bond.isGiven == false).toList();
    }

    // Search
    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((bond) =>
          (bond.source ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Sort
    if (selectedSort != null) {
      switch (selectedSort!) {
        case BondSort.amount:
          temp.sort(
                  (a, b) => (b.principal ?? 0).compareTo(a.principal ?? 0));
          break;
        case BondSort.interest:
          temp.sort(
                  (a, b) => (b.interestRate ?? 0).compareTo(a.interestRate ?? 0));
          break;
        case BondSort.maturity:
          temp.sort((a, b) {
            final aDate = a.endDate != null ? DateTime.tryParse(a.endDate!) : null;
            final bDate = b.endDate != null ? DateTime.tryParse(b.endDate!) : null;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });
          break;
      }
    }

    setState(() => filteredBonds = temp);
  }

  int get totalBonds => allBonds.length;
  int get lentCount => allBonds.where((bond) => bond.isGiven == true).length;
  int get debtCount => allBonds.where((bond) => bond.isGiven == false).length;

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Full-width Total Bonds
          _buildSummaryCard(
            "Total Near Maturity Bonds",
            "$totalBonds",
            Icons.bar_chart,
            Colors.blue,
            primaryText,
            fullWidth: true,
          ),
          const SizedBox(height: 12),

          // Lent/Debt summary row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Lent Bonds",
                  "$lentCount",
                  Icons.upload,
                  accent,
                  primaryText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  "Debt Bonds",
                  "$debtCount",
                  Icons.download,
                  Colors.red,
                  primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Buttons (frosted)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton("All", BondFilter.all, Colors.blue),
              _buildFilterButton("Lent", BondFilter.lent , accent),
              _buildFilterButton("Debt", BondFilter.debt, Colors.red),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          SizedBox(
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Bond Source',
                hintStyle: TextStyle(color: secondaryText, fontSize: 14),
                prefixIcon: Icon(Icons.search,
                    size: 20, color: secondaryText),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(fontSize: 14, color: primaryText),
              onChanged: (value) {
                searchQuery = value;
                applyFilter();
              },
            ),
          ),
          const SizedBox(height: 12),

          // Row: Minimal Sort + Type Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sort Button (Left)
              GestureDetector(
                onTap: () async {
                  final selected = await showModalBottomSheet<BondSort>(
                    context: context,
                    backgroundColor: Colors.grey[900],
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: BondSort.values.map((sort) {
                        return ListTile(
                          leading: const Icon(Icons.sort, color: Colors.white70),
                          title: Text(
                            sortLabel(sort),
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
                        selectedSort != null ? sortLabel(selectedSort!) : "Sort",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Type Toggle Button (Right)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedFilter == BondFilter.all) {
                      selectedFilter = BondFilter.lent;
                    } else if (selectedFilter == BondFilter.lent) {
                      selectedFilter = BondFilter.debt;
                    } else {
                      selectedFilter = BondFilter.all;
                    }
                    applyFilter();
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
                        selectedFilterLabel(),
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

          // Bond list or No Data
          if (filteredBonds.isEmpty)
            _buildNoDataCard(secondaryText)
          else
            ...filteredBonds.map(
                  (bond) => _buildBondCard(
                  bond, accent, secondaryText),
            ),
        ],
      ),
    );
  }

  // Frosted Glass Filter Button
  Widget _buildFilterButton(String text, BondFilter filter, Color color) {
    final bool isSelected = selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
          applyFilter();
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? [color.withOpacity(0.3), color.withOpacity(0.1)]
                    : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color.withOpacity(0.7) : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? color : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Summary Cards
  Widget _buildSummaryCard(String title, String value, IconData icon,
      Color iconColor, Color textColor,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth
          ? double.infinity
          : (MediaQuery.of(context).size.width - 42) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
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

  // Bond Card
  Widget _buildBondCard(
      LentLoanDTO bond, Color primaryText, Color secondaryText) {
    // Determine color based on type
    final Color accentColor = bond.isGiven == true ? Colors.blue : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          // Navigate to detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoanDetailScreen(loan: bond),
            ),
          );
        },
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
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet, color: accentColor, size: 32),
                title: Text(
                  "${bond.source ?? 'Unknown'} - ₹${(bond.principal ?? 0).toStringAsFixed(2)}",
                  style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Interest: ${(bond.interestRate ?? 0).toStringAsFixed(2)}% | "
                      "Maturity: ${bond.endDate ?? '-'} | "
                      "Type: ${bond.isGiven == true ? "Lent" : "Debt"}",
                  style: TextStyle(color: secondaryText),
                ),
                trailing: Icon(Icons.timelapse, color: Colors.orange),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // No Data Card
  Widget _buildNoDataCard(Color secondaryText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.01),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white24, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, color: Colors.grey[400], size: 48),
                const SizedBox(height: 12),
                Text(
                  "No Near Maturity Bonds",
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Try adjusting filters or check back later",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String selectedFilterLabel() {
    switch (selectedFilter) {
      case BondFilter.all:
        return "All";
      case BondFilter.lent:
        return "Lent";
      case BondFilter.debt:
        return "Debt";
    }
  }


  String sortLabel(BondSort sort) {
    switch (sort) {
      case BondSort.amount:
        return "Amount";
      case BondSort.interest:
        return "Interest";
      case BondSort.maturity:
        return "Maturity";
    }
  }
}

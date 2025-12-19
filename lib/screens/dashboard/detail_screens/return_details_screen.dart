import 'package:flutter/material.dart';
import '../../../models/return_model.dart';
import '../../../services/return_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/IndianCurrencyFormatter.dart';
import '../widgets/shimmerBox.dart';

class ReturnDetailsScreen extends StatefulWidget {
  final ReturnsList crop;

  const ReturnDetailsScreen({
    Key? key,
    required this.crop,
  }) : super(key: key);

  @override
  State<ReturnDetailsScreen> createState() => _ReturnDetailsScreenState();
}

class _ReturnDetailsScreenState extends State<ReturnDetailsScreen> {
  List<ReturnDetailModel> _returns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReturns();
  }

  Future<void> _fetchReturns() async {
    try {
      final fetched = await ReturnService().getReturnsByCropAndYear(
        cropId: widget.crop.cropId,
        year: DateTime.now().year,
      );
      setState(() => _returns = fetched);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch returns")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Return Details",
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _summaryCard(colors),
          Expanded(
            child: _isLoading
                ? _shimmerList(context)
                : _returns.isEmpty
                ? Center(
              child: Text(
                "No return records available",
                style: TextStyle(color: colors.secondaryText),
              ),
            )
                : _returnsList(colors),
          ),
        ],
      ),
    );
  }

  // ---------------- SUMMARY ----------------

  Widget _summaryCard(AppColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            colors.cardGradientStart.withOpacity(0.25),
            colors.cardGradientEnd.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: colors.border.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            widget.crop.cropName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                icon: Icons.agriculture,
                label: "Quantity",
                value: widget.crop.totalProduction.toString(),
                colors: colors,
              ),
              _summaryItem(
                icon: Icons.currency_rupee,
                label: "Returns",
                value: IndianCurrencyFormatter.format(
                  widget.crop.totalReturns.toString(),
                ),
                colors: colors,
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
    required AppColors colors,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: colors.accent),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: colors.secondaryText)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlight ? colors.accent : colors.text,
          ),
        ),
      ],
    );
  }

  Widget _returnsList(AppColors colors) {
    final grouped = groupByMonth(_returns);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),

            ...entry.value.map(
                  (ret) => _returnRow(ret, colors),
            ),

            // ✅ Monthly footer
            _monthFooter(entry.value, colors),
          ],
        );
      }).toList(),
    );
  }


  Widget _returnRow(ReturnDetailModel ret, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${ret.date.day}-${ret.date.month}-${ret.date.year}",
                style: TextStyle(color: colors.secondaryText, fontSize: 13),
              ),
              Text(
                "${ret.quantity} units",
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "₹${IndianCurrencyFormatter.format(ret.amount.toString())}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (ret.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ret.description,
              style: TextStyle(
                color: colors.text,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthFooter(
      List<ReturnDetailModel> returns,
      AppColors colors,
      ) {
    final totalAmount = _monthTotalAmount(returns);
    final totalQty = _monthTotalQuantity(returns);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.card.withOpacity(0.9),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Quantity
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Quantity",
                style: TextStyle(
                  fontSize: 12,
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalQty.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ],
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Total Returns",
                style: TextStyle(
                  fontSize: 12,
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "₹${IndianCurrencyFormatter.format(totalAmount.toString())}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _monthTotalAmount(List<ReturnDetailModel> list) {
    return list.fold(0, (sum, e) => sum + e.amount);
  }

  double _monthTotalQuantity(List<ReturnDetailModel> list) {
    return list.fold(0, (sum, e) => sum + e.quantity);
  }


  Map<String, List<ReturnDetailModel>> groupByMonth(
      List<ReturnDetailModel> returns) {
    final Map<String, List<ReturnDetailModel>> grouped = {};
    for (var ret in returns) {
      final key = "${_monthName(ret.date.month)} ${ret.date.year}";
      grouped.putIfAbsent(key, () => []).add(ret);
    }
    return grouped;
  }

  String _monthName(int month) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[month - 1];
  }

  Widget _monthlyShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header
        shimmerBox(
          context: context,
          height: 18,
          width: 140,
          margin: const EdgeInsets.symmetric(vertical: 12),
        ),

        // Return cards
        shimmerBox(
          context: context,
          height: 80,
          margin: const EdgeInsets.only(bottom: 8),
        ),
        shimmerBox(
          context: context,
          height: 80,
          margin: const EdgeInsets.only(bottom: 8),
        ),
        shimmerBox(
          context: context,
          height: 80,
        ),

        // Monthly footer
        shimmerBox(
          context: context,
          height: 56,
          margin: const EdgeInsets.only(top: 10, bottom: 20),
        ),
      ],
    );
  }

  Widget _shimmerList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        3, // show 3 months shimmer
            (_) => _monthlyShimmer(context),
      ),
    );
  }

}

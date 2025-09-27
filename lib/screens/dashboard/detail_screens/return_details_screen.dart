import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/return_model.dart';
import '../../../services/return_service.dart';

class ReturnDetailsScreen extends StatefulWidget {
  final ReturnsList crop; // cropName, totalReturns, totalProduction, cropId
  final Color scaffoldBg;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const ReturnDetailsScreen({
    Key? key,
    required this.crop,
    required this.scaffoldBg,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
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
    setState(() => _isLoading = true);
    try {
      final fetched = await ReturnService().getReturnsByCropAndYear(
        cropId: widget.crop.cropId,
        year: DateTime.now().year,
      );
      setState(() => _returns = fetched);
    } catch (e) {
      print("Error fetching returns: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch returns.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text("Return Details", style: TextStyle(color: widget.primaryText)),
      ),
      body: Column(
        children: [
          // ❄ Frosted crop summary card
          // ❄ Frosted crop summary card - elegant design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        widget.cardGradientStart.withOpacity(0.3),
                        widget.cardGradientEnd.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: widget.cardBorder.withOpacity(0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Crop Name
                      Text(
                        widget.crop.cropName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Divider
                      Divider(color: widget.secondaryText.withOpacity(0.3), thickness: 1),
                      const SizedBox(height: 20),
                      // Quantity and Returns
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Quantity
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.cardGradientStart.withOpacity(0.2),
                                ),
                                child: const Icon(Icons.agriculture, size: 28, color: Colors.orangeAccent),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Quantity",
                                style: TextStyle(fontSize: 14, color: widget.secondaryText),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${widget.crop.totalProduction}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.primaryText,
                                ),
                              ),
                            ],
                          ),
                          // Returns
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.cardGradientEnd.withOpacity(0.2),
                                ),
                                child: const Icon(Icons.attach_money, size: 28, color: Colors.green),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Returns",
                                style: TextStyle(fontSize: 14, color: widget.secondaryText),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹${widget.crop.totalReturns}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),


          // ❄ Returns List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _returns.isEmpty
                ? Center(
              child: Text(
                "No return records available",
                style: TextStyle(
                    color: widget.secondaryText, fontSize: 16),
              ),
            )
                : ListView(
              padding: const EdgeInsets.all(16),
              children: groupByMonth(_returns).entries.map((entry) {
                final month = entry.key;
                final returnsInMonth = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        month,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryText,
                        ),
                      ),
                    ),

                    // Cards for this month
                    ...returnsInMonth.map((ret) => ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.cardGradientStart.withOpacity(0.2),
                                widget.cardGradientEnd.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: widget.cardBorder.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Line 1: Date | Quantity | Amount
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${ret.date.year}-${ret.date.month.toString().padLeft(2, '0')}-${ret.date.day.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: widget.secondaryText, fontSize: 14),
                                  ),
                                  Text(
                                    "${ret.quantity} units",
                                    style: TextStyle(color: widget.accent, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "₹${ret.amount}",
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Line 2: Description
                              if (ret.description.isNotEmpty)
                                Text(
                                  ret.description,
                                  style: TextStyle(
                                    color: widget.primaryText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  Map<String, List<ReturnDetailModel>> groupByMonth(List<ReturnDetailModel> returns) {
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

  Widget _infoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

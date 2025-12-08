import 'package:flutter/material.dart';
import '../../../services/TractorService/tractor_service.dart';
import 'package:flutter/services.dart';

class PaymentDetailsPage extends StatefulWidget {
  final int activityId;
  final String title;
  final double totalAmount;
  final double amountReceived;
  final String date;
  final double acres;

  const PaymentDetailsPage({
    Key? key,
    required this.activityId,
    required this.title,
    required this.totalAmount,
    required this.amountReceived,
    required this.date,
    required this.acres,
  }) : super(key: key);

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  final TextEditingController _paymentController = TextEditingController();
  final tractorService = TractorService();
  bool _loading = false;

  double get remaining => widget.totalAmount - widget.amountReceived;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = _AppColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.text,
            fontSize: 20,
          ),
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildDetailsCard(colors),
                      const SizedBox(height: 20),

                      if (remaining == 0) _buildFullyPaidCard(),
                      if (remaining > 0) _buildAddPaymentCard(colors, isDark),

                      const Spacer(),

                      if (remaining > 0) _buildClosePaymentButton(colors),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= UI SECTIONS ==================

  Widget _buildDetailsCard(_AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildRow("Acres Worked", "${widget.acres} acres", colors),
          _buildRow("Activity Date", widget.date, colors),
          const Divider(height: 24),
          _buildRow("Total Amount", "₹${widget.totalAmount}", colors, bold: true),
          _buildRow("Amount Received", "₹${widget.amountReceived}", colors),
          _buildRow(
            "Remaining Amount",
            "₹${remaining.toStringAsFixed(0)}",
            colors,
            color: remaining > 0 ? Colors.orange.shade700 : Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildFullyPaidCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Amount fully received.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddPaymentCard(_AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Add Payment",
              style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          TextField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MaxAmountFormatter(remaining),
            ],
            decoration: InputDecoration(
              hintText: "Enter amount",
              prefixIcon: const Icon(Icons.currency_rupee),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Payment",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _loading ? null : _addPaymentAPI,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosePaymentButton(_AppColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.lock, color: Colors.white),
        label: const Text("Close Payment",
            style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _loading ? null : _closePaymentAPI,
      ),
    );
  }

  // ================== API CALLS ===================

  Future<void> _addPaymentAPI() async {
    final amount = double.tryParse(_paymentController.text);

    if (amount == null || amount <= 0) {
      _showSnack("Enter valid amount", Colors.red);
      return;
    }
    if (amount > remaining) {
      _showSnack("Amount exceeds remaining", Colors.orange);
      return;
    }

    setState(() => _loading = true);
    final res = await tractorService.addClosePayment(
      activityId: widget.activityId,
      paymentAmount: amount,
    );
    setState(() => _loading = false);

    if (!mounted) return;

    if (res.statusCode == 200) {
      _showSnack("Payment added!", Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnack("Failed to add payment", Colors.red);
    }
  }

  Future<void> _closePaymentAPI() async {
    setState(() => _loading = true);

    final res = await tractorService.addClosePayment(
      activityId: widget.activityId,
      paymentAmount: remaining,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (res.statusCode == 200) {
      _showSnack("Payment closed!", Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnack("Failed to close payment", Colors.red);
    }
  }

  // ================== HELPERS ===================

  Widget _buildRow(String title, String value, _AppColors colors,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: colors.text.withOpacity(0.7))),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color ?? colors.text,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

class _MaxAmountFormatter extends TextInputFormatter {
  final double max;

  _MaxAmountFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final value = double.tryParse(newValue.text) ?? 0;

    if (value > max) {
      return oldValue;
    }

    return newValue;
  }
}

class _AppColors {
  final Color background;
  final Color card;
  final Color text;

  _AppColors(bool isDark)
      : background = isDark ? const Color(0xFF081712) : Colors.white,
        card = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3),
        text = isDark ? Colors.white : const Color(0xFF1A1A1A);
}

import 'package:flutter/material.dart';
import '../../../models/investment.dart';
import '../../services/worker_service.dart';

class WorkerListScreen extends StatefulWidget {
  final Investment investment;
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  /// Callback to refresh parent screen when payment changes
  final VoidCallback? onPaymentUpdated;

  const WorkerListScreen({
    Key? key,
    required this.investment,
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.scaffoldBg,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
    this.onPaymentUpdated,
  }) : super(key: key);

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  late List<Worker> workers;

  @override
  void initState() {
    super.initState();
    workers = widget.investment.workers ?? [];
  }

  void _togglePaymentStatus(Worker worker) async {
    final newStatus = !worker.paymentDone;
    try {
      final updatedWorker = await WorkerService().updateWorkerPayment(worker.id, newStatus);

      setState(() {
        final index = workers.indexWhere((w) => w.id == worker.id);
        if (index != -1 && updatedWorker != null) workers[index] = updatedWorker;
      });

      // Notify parent screen to refresh investment data
      if (widget.onPaymentUpdated != null) widget.onPaymentUpdated!();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? "Payment ₹${worker.wage.toStringAsFixed(0)} done to ${worker.name}"
                : "Payment marked as unpaid for ${worker.name}",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update payment for ${worker.name}"),
          duration: const Duration(seconds: 2),
        ),
      );
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
        title: Text(
          "Workers - ${widget.investment.description}",
          style: TextStyle(
            color: widget.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: workers.isEmpty
          ? Center(
        child: Text(
          "No workers assigned",
          style: TextStyle(color: widget.secondaryText, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  widget.cardGradientStart.withOpacity(0.25),
                  widget.cardGradientEnd.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: widget.cardBorder.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Worker details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker.role,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.secondaryText,
                      ),
                    ),
                  ],
                ),
                // Payment status button & wage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${worker.wage.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _togglePaymentStatus(worker),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: worker.paymentDone ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          worker.paymentDone ? "Paid" : "Pay Now",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

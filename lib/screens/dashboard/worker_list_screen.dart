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
  final WorkerService _service = WorkerService();

  // State
  List<Worker> fullList = [];
  List<Worker> visibleList = [];

  String search = "";
  String filter = "ALL";

  // Pagination
  int currentIndex = 0;
  final int itemsPerPage = 20;
  bool loadingMore = false;

  final ScrollController scrollCtrl = ScrollController();
  bool showShimmer = true;

  @override
  void initState() {
    super.initState();

    // initial workers from investment
    fullList = List.from(widget.investment.workers ?? []);

    // Apply shimmer effect for UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => showShimmer = false);
      }
    });

    _resetPagination();

    scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollCtrl.dispose();
    super.dispose();
  }

  // ---------------- Pagination ----------------
  void _resetPagination() {
    currentIndex = itemsPerPage;
    visibleList = fullList.take(currentIndex).toList();
    setState(() {});
  }

  void _loadMore() async {
    if (loadingMore) return;
    if (currentIndex >= fullList.length) return;

    loadingMore = true;

    await Future.delayed(const Duration(milliseconds: 150));

    int nextIndex = currentIndex + itemsPerPage;
    if (nextIndex > fullList.length) nextIndex = fullList.length;

    visibleList = fullList.take(nextIndex).toList();
    currentIndex = nextIndex;

    loadingMore = false;
    setState(() {});
  }

  void _onScroll() {
    if (scrollCtrl.position.pixels >
        scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  // ---------------- Search + Filter ----------------
  void _applyFilters() {
    List<Worker> list = List.from(widget.investment.workers ?? []);

    // Search
    if (search.isNotEmpty) {
      list = list
          .where((w) => w.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    // Filter
    if (filter == "PAID") {
      list = list.where((w) => w.paymentDone).toList();
    } else if (filter == "UNPAID") {
      list = list.where((w) => !w.paymentDone).toList();
    }

    fullList = list;
    _resetPagination();
  }

  // ---------------- Payment Toggle ----------------
  Future<void> _togglePayment(Worker worker) async {
    final newStatus = !worker.paymentDone;

    try {
      Worker? updated =
      await _service.updateWorkerPayment(worker.id, newStatus);

      if (updated != null) {
        // update locally in investment workers
        final idx = widget.investment.workers!
            .indexWhere((w) => w.id == worker.id);
        widget.investment.workers![idx] = updated;

        // Reapply filters
        _applyFilters();

        // Notify parent
        widget.onPaymentUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? "Payment done to ${worker.name}"
                  : "Marked unpaid: ${worker.name}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update ${worker.name}")),
      );
    }
  }

  // ---------------- UI ----------------

  // Shimmer loader
  Widget _shimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 70,
        decoration: BoxDecoration(
          color: widget.cardBorder.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _workerTile(Worker w) {
    return Dismissible(
      key: ValueKey(w.id),
      background: _swipeBg(Colors.green, "Mark Paid"),
      secondaryBackground: _swipeBg(Colors.red, "Mark Unpaid"),
      confirmDismiss: (dir) async {
        await _togglePayment(w);
        return false; // keep item in list
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              widget.cardGradientStart.withOpacity(0.25),
              widget.cardGradientEnd.withOpacity(0.2),
            ],
          ),
          border: Border.all(color: widget.cardBorder.withOpacity(0.6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // left
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  style: TextStyle(
                    color: widget.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  w.role,
                  style: TextStyle(color: widget.secondaryText),
                ),
              ],
            ),

            // right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${w.wage.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: widget.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _statusChip(w.paymentDone),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusChip(bool paid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: paid ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        paid ? "Paid" : "Unpaid",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _swipeBg(Color color, String text) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: color.withOpacity(0.7),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text(
          "Workers - ${widget.investment.description}",
          style: TextStyle(color: widget.primaryText),
        ),
      ),

      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) {
                search = val;
                _applyFilters();
              },
              style: TextStyle(color: widget.primaryText),
              decoration: InputDecoration(
                hintText: "Search worker...",
                hintStyle: TextStyle(color: widget.secondaryText),
                prefixIcon: Icon(Icons.search, color: widget.secondaryText),
                filled: true,
                fillColor: widget.cardBorder.withOpacity(0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                _filterBtn("ALL"),
                const SizedBox(width: 10),
                _filterBtn("PAID"),
                const SizedBox(width: 10),
                _filterBtn("UNPAID"),
              ],
            ),
          ),

          // WORKER LIST
          Expanded(
            child: showShimmer
                ? _shimmer()
                : visibleList.isEmpty
                ? Center(
              child: Text(
                "No workers found",
                style: TextStyle(color: widget.secondaryText),
              ),
            )
                : ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: visibleList.length,
              itemBuilder: (_, i) => _workerTile(visibleList[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String label) {
    final selected = filter == label;

    return GestureDetector(
      onTap: () {
        filter = label;
        _applyFilters();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? widget.accent
              : widget.cardBorder.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : widget.secondaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

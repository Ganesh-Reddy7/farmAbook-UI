import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/BottomSheetNote.dart';
import '../../../utils/formatIndianNumber.dart';
import '../../../widgets/common_info_bottom_sheet.dart';
import '../models/interest_history.dart';
import '../providers/interest_calculator_provider.dart';
import '../widgets/InterestHistoryShimmer.dart';

class InterestHistoryScreen extends ConsumerStatefulWidget {
  const InterestHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InterestHistoryScreen> createState() =>
      _InterestHistoryScreenState();
  }

class _InterestHistoryScreenState
    extends ConsumerState<InterestHistoryScreen> {

  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(interestCalculatorProvider.notifier).fetchHistory();
    });
  }

  Future<void> _confirmClearHistory(AppColors colors) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Clear History?",
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "This will permanently delete all interest calculations. This action cannot be undone.",
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: colors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Clear",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(interestCalculatorProvider.notifier).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interestCalculatorProvider);
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
          "Calculation History",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: colors.text),
            onPressed: () {
              CommonInfoBottomSheet.show(
                context: context,
                title: "History Tips",
                notes: const [
                  BottomSheetNote(
                    icon: Icons.swipe_left,
                    title: "Swipe to Delete",
                    description:
                    "Swipe left on a calculation to delete it from history.",
                  ),
                  BottomSheetNote(
                    icon: Icons.cleaning_services_outlined,
                    title: "Keep History Clean",
                    description:
                    "Clearing old calculations helps improve performance and avoids overload.",
                  ),
                ],
              );
            },
          ),

          if (state.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              color: Colors.redAccent,
              tooltip: "Clear history",
              onPressed: () => _confirmClearHistory(colors),
            ),
        ],
      ),


      body: state.loading
          ? const InterestHistoryShimmer()
          : state.history.isEmpty
          ? _emptyState(colors)
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final item = state.history[index];
          return _dismissibleItem(item, colors);
        },
      ),
    );
  }

  Widget _dismissibleItem(
      InterestHistory item,
      AppColors colors,
      ) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref
            .read(interestCalculatorProvider.notifier)
            .deleteWithUndo(item, context);
      },
      child: _historyCard(item, colors),
    );
  }


  Widget _emptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48, color: colors.secondaryText),
          const SizedBox(height: 12),
          Text(
            "No calculations yet",
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your interest calculations will appear here",
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(dynamic item, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _typeChip(item.calculationType, colors),
              Text(
                "${dateFormat.format(item.startDate)} - ${dateFormat.format(item.endDate)}",
                style: TextStyle(
                  fontSize: 12,
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row("Principal", item.principal, colors),
          const SizedBox(height: 6),
          _row("Interest", item.interestAmount, colors),
          const Divider(height: 20),
          _row(
            "Total Amount",
            item.totalAmount,
            colors,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
      String label,
      num value,
      AppColors colors, {
        bool highlight = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.secondaryText,
          ),
        ),
        Text(
          NumberUtils.formatINR(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight ? colors.accent : colors.text,
          ),
        ),
      ],
    );
  }

  Widget _typeChip(String type, AppColors colors) {
    final isSimple = type.toUpperCase() == "SIMPLE";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSimple
            ? colors.accent.withOpacity(0.15)
            : Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSimple ? "Simple" : "Compound",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSimple ? colors.accent : Colors.orange,
        ),
      ),
    );
  }
}

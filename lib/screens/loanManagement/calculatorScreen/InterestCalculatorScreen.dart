import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatIndianNumber.dart';
import '../../../utils/slide_route.dart';
import '../../../widgets/commonDateSelector.dart';
import '../../../widgets/common_bottom_sheet_selector.dart';
import '../providers/interest_calculator_provider.dart';
import 'historyScreen.dart';

enum InterestType { simple, compound }

class InterestCalculatorScreen extends ConsumerStatefulWidget {
  const InterestCalculatorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InterestCalculatorScreen> createState() =>
      _InterestCalculatorScreenState();
}

class _InterestCalculatorScreenState
    extends ConsumerState<InterestCalculatorScreen> {

  InterestType selectedType = InterestType.simple;

  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  int compounding = 1;
  final dateFormat = DateFormat('dd MMM yyyy');

  void calculate() {
    final principal = double.tryParse(
      amountCtrl.text.replaceAll(',', ''),
    ) ?? 0;
    final double rate = double.tryParse(rateCtrl.text) ?? 0;

    if (principal <= 0 ||
        rate <= 0 ||
        startDate == null ||
        endDate == null ||
        endDate!.isBefore(startDate!)) {
      _showError();
      return;
    }

    ref.read(interestCalculatorProvider.notifier).calculate(
      principal: principal,
      rate: rate,
      startDate: startDate!,
      endDate: endDate!,
      compoundingFrequency: compounding,
      type: selectedType,
    );
  }


  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter valid values")),
    );
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await CommonDateSelector.show(
      context: context,
      title: isStart ? "Select Start Date" : "Select End Date",
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? startDate ?? DateTime.now()),
      minDate: isStart
          ? DateTime(2000)
          : (startDate ?? DateTime(2000)), // ✅ KEY LINE
      maxDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;

          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(interestCalculatorProvider);
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
          "Interest Calculator",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: colors.text,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "History",
            icon: Icon(
              Icons.history,
              color: colors.text,
            ),
            onPressed: () {
              Navigator.of(context).push(
                SlideFromRightRoute(
                  page: const InterestHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _interestTypeSelector(),
          const SizedBox(height: 16),

          _inputField("Principal Amount", amountCtrl , colors , indianFormat: true,),
          const SizedBox(height: 12),
          _inputField("Interest Rate (%)", rateCtrl , colors),
          const SizedBox(height: 16),
          _dateRow(),
          const SizedBox(height: 16),

          if (selectedType == InterestType.compound)
            _compoundSelector(),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: calcState.loading ? null : calculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: calcState.loading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.calculate, size: 20),
                SizedBox(width: 8),
                Text(
                  "Calculate",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (calcState.result != null)
            _resultCard(
              calcState.result!.interest,
              calcState.result!.totalAmount,
            ),
          if (calcState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                calcState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

        ],
      ),
    );
  }

  Widget _interestTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segmentItem(
            label: "Simple Interest",
            isSelected: selectedType == InterestType.simple,
            onTap: () {
              setState(() {
                selectedType = InterestType.simple;
              });
            },
          ),
          _segmentItem(
            label: "Compound Interest",
            isSelected: selectedType == InterestType.compound,
            onTap: () {
              setState(() {
                selectedType = InterestType.compound;
              });
            },
          ),
        ],
      ),
    );
  }
  Widget _segmentItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      String label,
      TextEditingController controller,
      AppColors colors, {
        bool indianFormat = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: indianFormat
          ? (value) {
        if (value.isEmpty) return;

        // Remove commas
        final cleaned = value.replaceAll(',', '');

        // Split integer & decimal parts
        final parts = cleaned.split('.');
        final integerPart = parts[0];

        // If integer part is empty, don't format yet
        if (integerPart.isEmpty) return;

        final intValue = int.tryParse(integerPart);
        if (intValue == null) return;

        // Format integer part only
        final formattedInt =
        NumberUtils.formatIndianPlain(intValue);

        // Reattach decimal part if exists
        final formatted = parts.length > 1
            ? '$formattedInt.${parts[1]}'
            : formattedInt;

        if (formatted != value) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: formatted.length,
            ),
          );
        }
      }
          : null,
      style: TextStyle(
        color: colors.text,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colors.secondaryText,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: colors.card.withOpacity(0.6),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.border.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.accent,
            width: 1.6,
          ),
        ),
      ),
    );
  }



  Widget _dateRow() {
    return Row(
      children: [
        Expanded(
          child: _dateCard(
            title: "Start Date",
            value: startDate != null
                ? dateFormat.format(startDate!)
                : "Select",
            onTap: () => pickDate(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateCard(
            title: "End Date",
            value: endDate != null
                ? dateFormat.format(endDate!)
                : "Select",
            onTap: () => pickDate(false),
          ),
        ),
      ],
    );
  }

  Widget _dateCard({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: colors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _compoundSelector() {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final selected = await CommonBottomSheetSelector.show<int>(
          context: context,
          title: "Compounding Frequency",
          items: const [1, 2, 4, 12],
          selected: compounding,
          displayText: (value) {
            switch (value) {
              case 1:
                return "Yearly";
              case 2:
                return "Half-Yearly";
              case 4:
                return "Quarterly";
              case 12:
                return "Monthly";
              default:
                return value.toString();
            }
          },
          backgroundColor: colors.card,
          textColor: colors.text,
        );

        if (selected != null) {
          setState(() {
            compounding = selected;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.repeat, color: colors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _compoundLabel(compounding),
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: colors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  String _compoundLabel(int value) {
    switch (value) {
      case 1:
        return "Yearly";
      case 2:
        return "Half-Yearly";
      case 4:
        return "Quarterly";
      case 12:
        return "Monthly";
      default:
        return "Select Frequency";
    }
  }



  Widget _resultCard(double interest, double totalAmount) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          _resultRow("Interest Earned", interest),
          const SizedBox(height: 10),
          Divider(color: colors.divider),
          const SizedBox(height: 10),
          _resultRow("Total Amount", totalAmount),
        ],
      ),
    );
  }

  Widget _resultRow(String label, double value) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.secondaryText,
            ),
          ),
          Text(
            NumberUtils.formatINR(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }


}

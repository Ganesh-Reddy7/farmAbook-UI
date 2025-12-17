import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CommonDateSelector {
  static Future<DateTime?> show({
    required BuildContext context,
    required String title,
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    DateTime tempDate = initialDate ?? DateTime.now();

    return await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _DatePickerSheet(
          title: title,
          initialDate: tempDate,
          minDate: minDate ?? DateTime(2000),
          maxDate: maxDate ?? DateTime(2100),
        );
      },
    );
  }
}

class _DatePickerSheet extends StatefulWidget {
  final String title;
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;

  const _DatePickerSheet({
    required this.title,
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
  });

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        border: Border.all(
          color: colors.divider.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------------- HEADER ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colors.secondaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          Divider(color: colors.divider),

          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: colors.accent, // selected date
                onPrimary: Colors.green,
                onSurface: colors.text,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: widget.minDate,
              lastDate: widget.maxDate,
              onDateChanged: (date) {
                setState(() => selectedDate = date);
              },
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, selectedDate);
              },
              child: const Text(
                "Confirm",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

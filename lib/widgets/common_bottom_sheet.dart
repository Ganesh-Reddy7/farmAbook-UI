import 'package:flutter/material.dart';

class CommonBottomSheet {
  static Future<String?> showSelector({
    required BuildContext context,
    required List<String> options,
    required String selectedValue,
    required Color background,
    required Color textColor,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top indicator
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            ...options.map((item) {
              final isSelected = item == selectedValue;
              return ListTile(
                title: Text(
                  item,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, item),
              );
            }),

            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

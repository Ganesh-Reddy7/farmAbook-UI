import 'package:flutter/material.dart';

class NoDataWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isDark;

  const NoDataWidget({
    Key? key,
    required this.message,
    required this.isDark,
    this.icon = Icons.info_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark ? Colors.white70 : Colors.black54;
    final Color cardColor = isDark ? const Color(0xFF081712) : Colors.grey.shade100;
    final Color iconColor = isDark ? Colors.white54 : Colors.black38;

    return Container(
      width: double.infinity,                 // 🔥 FULL WIDTH FIX
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

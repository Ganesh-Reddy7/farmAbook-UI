import 'package:flutter/material.dart';
class FrostedInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged; // ✅ ADD THIS
  final TextInputType keyboardType;
  final bool compact;

  const FrostedInput({
    Key? key,
    required this.label,
    required this.icon,
    this.controller,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged, // ✅ ADD THIS
    this.keyboardType = TextInputType.text,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onTap: onTap,
        onChanged: onChanged, // ✅ WIRE IT HERE
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: compact ? 13 : 15,
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: compact ? 13 : 15,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}


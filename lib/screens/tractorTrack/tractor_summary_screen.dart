import 'package:flutter/material.dart';

class TractorSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tractors;
  const TractorSummaryScreen({Key? key, required this.tractors}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Center(
      child: Text(
        "Tractor Summary (All tractors combined)",
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}

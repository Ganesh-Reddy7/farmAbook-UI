import 'package:flutter/material.dart';

import '../../../utils/IndianCurrencyFormatter.dart';
import '../../../widgets/FrostedInput.dart';

class Worker {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController wageCtrl = TextEditingController();
  final VoidCallback onChange;

  Worker({required this.onChange}) {
    wageCtrl.addListener(onChange);
  }

  double get wage =>
      IndianCurrencyFormatter.parse(wageCtrl.text);

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          FrostedInput(
            label: "Worker Name",
            icon: Icons.person,
            controller: nameCtrl,
            compact: true,
          ),
          const SizedBox(height: 6),
          FrostedInput(
            label: "Wage (₹)",
            icon: Icons.currency_rupee,
            controller: wageCtrl,
            keyboardType: TextInputType.number,
            compact: true,
            onChanged: (v) {
              final f = IndianCurrencyFormatter.format(v);
              if (f != v) {
                wageCtrl.value = TextEditingValue(
                  text: f,
                  selection:
                  TextSelection.collapsed(offset: f.length),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    "name": nameCtrl.text,
    "wage": wage,
  };

  void dispose() {
    nameCtrl.dispose();
    wageCtrl.dispose();
  }
}

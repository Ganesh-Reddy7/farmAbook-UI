import 'dart:io';
import 'package:flutter/material.dart';
import '../../../services/loan_service.dart';
import '../../../widgets/FrostedInput.dart';

class AddLoanScreen extends StatefulWidget {
  final bool isGiven;

  const AddLoanScreen({Key? key, required this.isGiven}) : super(key: key);

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController sourceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController interestController = TextEditingController();
  final TextEditingController maturityController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? startDate;
  File? bondFile;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF081712) : Colors.white;
    final Color accent = widget.isGiven ? (isDark ? Colors.greenAccent.shade200 : Colors.green.shade700) : (isDark ? Colors.redAccent.shade200 : Colors.red.shade700);
    final String title = widget.isGiven ? "Add Lent Loan" : "Add Debt";

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(color: accent, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double formWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
          return Center(
            child: SizedBox(
              width: formWidth,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        FrostedInput(
                          label: "Name",
                          icon: Icons.person,
                          controller: sourceController,
                        ),
                        const SizedBox(height: 16),

                        FrostedInput(
                          label: "Amount",
                          icon: Icons.attach_money,
                          controller: amountController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        FrostedInput(
                          label: "Interest (%)",
                          icon: Icons.percent,
                          controller: interestController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        FrostedInput(
                          label: "Start Date",
                          icon: Icons.date_range,
                          readOnly: true,
                          onTap: _pickStartDate,
                          controller: TextEditingController(
                            text: startDate != null
                                ? "${startDate!.toLocal()}".split(' ')[0]
                                : "",
                          ),
                        ),
                        const SizedBox(height: 16),

                        FrostedInput(
                          label: "Maturity Period (Years)",
                          icon: Icons.calendar_today,
                          controller: maturityController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        FrostedInput(
                          label: "Description",
                          icon: Icons.description,
                          controller: descriptionController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                bool success =
                                await LoanService().addLentLoan(
                                  source: sourceController.text,
                                  amount: double.tryParse(amountController.text) ?? 0,
                                  interest: double.tryParse(interestController.text) ?? 0,
                                  startDate: startDate ?? DateTime.now(),
                                  maturityYears:
                                  int.tryParse(maturityController.text) ?? 0,
                                  description: descriptionController.text,
                                  isGiven: widget.isGiven,
                                );

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        widget.isGiven
                                            ? "Lent loan added successfully!"
                                            : "Debt added successfully!",
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        widget.isGiven
                                            ? "Failed to add lent loan."
                                            : "Failed to add debt.",
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              "Add",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white, // change this to what you want
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/return_service.dart';
import '../../../services/investment_service.dart';
import '../../../models/crop.dart';
import '../../../widgets/FrostedDropDown.dart';
import '../../../widgets/FrostedInput.dart';

class AddReturnScreen extends StatefulWidget {
  final Color scaffoldBg;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const AddReturnScreen({
    Key? key,
    required this.scaffoldBg,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
  }) : super(key: key);

  @override
  State<AddReturnScreen> createState() => _AddReturnScreenState();
}

class _AddReturnScreenState extends State<AddReturnScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController =  TextEditingController();
  cropDTO? _selectedCrop;
  List<cropDTO> _cropOptions = [];
  DateTime? _selectedDate;
  bool _isSaving = false;
  bool _loadingCrops = false;

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    setState(() => _loadingCrops = true);
    try {
      _cropOptions = await InvestmentService().getCrops(DateTime.now().year);
    } catch (e) {
      print("Failed to fetch crops: $e");
    } finally {
      setState(() => _loadingCrops = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text(
          "Add Return",
          style: TextStyle(
            color: widget.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateField(),
            const SizedBox(height: 12),
            FrostedDropdown(
              label: "Select Crop",
              icon: Icons.agriculture,
              options: _cropOptions.map((c) => c.cropName).toList(),
              selectedValue: _selectedCrop?.cropName,
              onChanged: (value) {
                setState(() {
                  _selectedCrop =
                      _cropOptions.firstWhere((c) => c.cropName == value);
                });
              },
              compact: true,
            ),
            const SizedBox(height: 12),
            FrostedInput(
              label: "Quantity",
              icon: Icons.production_quantity_limits, // better icon for quantity
              controller: _quantityController,       // make sure you have a separate controller for quantity
              keyboardType: TextInputType.number,
              compact: true,
            ),

            const SizedBox(height: 12),
            FrostedInput(
              label: "Amount (₹)",
              icon: Icons.currency_rupee,
              controller: _amountController,
              keyboardType: TextInputType.number,
              compact: true,
            ),
            const SizedBox(height: 12),
            _buildFrostedInput(
                "Description", Icons.note, _descriptionController,
                maxLines: 2, compact: true),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return FrostedInput(
      label: "Select Date",
      icon: Icons.calendar_today,
      controller: TextEditingController(
        text: _selectedDate != null
            ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.day.toString().padLeft(2,'0')}"
            : "",
      ),
      readOnly: true,
      onTap: _pickDate,
      compact: true,
    );
  }

  Widget _buildFrostedInput(String label, IconData icon,
      TextEditingController controller,
      {int maxLines = 1, bool compact = false}) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 8 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: compact ? 13 : 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
              labelText: label,
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: compact ? 13 : 15),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isSaving ? null : _saveReturn,
        child: _isSaving
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Text("Save Return"),
      ),
    );
  }

  void _pickDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveReturn() async {
    if (_selectedDate == null || _descriptionController.text.isEmpty || _amountController.text.isEmpty || _selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    final success = await ReturnService().saveReturn(
      amount: amount,
      description: _descriptionController.text,
      date: _selectedDate!,
      cropId: _selectedCrop!.cropId,
      quantity:quantity
    );

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Return Saved!"), backgroundColor: widget.accent),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save return."), backgroundColor: Colors.redAccent),
      );
    }
  }
}

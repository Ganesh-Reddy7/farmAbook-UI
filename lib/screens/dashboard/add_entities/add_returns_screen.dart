import 'package:flutter/material.dart';
import '../../../services/return_service.dart';
import '../../../services/investment_service.dart';
import '../../../models/crop.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/IndianCurrencyFormatter.dart';
import '../../../widgets/FrostedDropDown.dart';
import '../../../widgets/FrostedInput.dart';
import '../../../widgets/commonDateSelector.dart';

class AddReturnScreen extends StatefulWidget {
  const AddReturnScreen({Key? key}) : super(key: key);

  @override
  State<AddReturnScreen> createState() => _AddReturnScreenState();
}

class _AddReturnScreenState extends State<AddReturnScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();

  cropDTO? _selectedCrop;
  List<cropDTO> _cropOptions = [];

  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _quantityCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCrops() async {
    _cropOptions = await InvestmentService().getCrops(DateTime.now().year);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Return",
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _dateField(),
            const SizedBox(height: 12),

            FrostedDropdown(
              label: "Select Crop",
              icon: Icons.agriculture,
              options: _cropOptions.map((c) => c.cropName).toList(),
              selectedValue: _selectedCrop?.cropName,
              compact: true,
              onChanged: (v) => setState(
                    () => _selectedCrop =
                    _cropOptions.firstWhere((c) => c.cropName == v),
              ),
            ),

            const SizedBox(height: 12),

            FrostedInput(
              label: "Quantity",
              icon: Icons.production_quantity_limits,
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              compact: true,
            ),

            const SizedBox(height: 12),

            FrostedInput(
              label: "Amount (₹)",
              icon: Icons.currency_rupee,
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              compact: true,
              onChanged: _currencyFormatter(_amountCtrl),
            ),

            const SizedBox(height: 12),

            FrostedInput(
              label: "Description",
              icon: Icons.note,
              controller: _descCtrl,
              maxLines: 2,
              compact: true,
            ),

            const SizedBox(height: 24),
            _saveButton(colors),
          ],
        ),
      ),
    );
  }

  Widget _dateField() {
    return FrostedInput(
      label: "Select Date",
      icon: Icons.calendar_today,
      controller: _dateCtrl,
      readOnly: true,
      compact: true,
      onTap: _pickDate,
    );
  }

  Widget _saveButton(AppColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveReturn,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text("Save Return"),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await CommonDateSelector.show(
      context: context,
      title: "Select Return Date",
      initialDate: _selectedDate ?? DateTime.now(),
      minDate: DateTime(2000),
      maxDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  ValueChanged<String> _currencyFormatter(TextEditingController controller) {
    return (value) {
      final raw = value.replaceAll(',', '');
      if (raw.isEmpty) return;

      final num = double.tryParse(raw);
      if (num == null) return;

      final formatted = IndianCurrencyFormatter.format(raw);
      if (formatted != value) {
        controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    };
  }

  Future<void> _saveReturn() async {
    if (_selectedDate == null ||
        _selectedCrop == null ||
        _descCtrl.text.isEmpty ||
        _amountCtrl.text.isEmpty ||
        _quantityCtrl.text.isEmpty) {
      _showSnack("Please fill all fields");
      return;
    }

    setState(() => _isSaving = true);

    final success = await ReturnService().saveReturn(
      amount: double.parse(_amountCtrl.text.replaceAll(',', '')),
      quantity: double.parse(_quantityCtrl.text),
      description: _descCtrl.text,
      date: _selectedDate!,
      cropId: _selectedCrop!.cropId,
    );

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      _showSnack("Failed to save return");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

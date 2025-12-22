import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/TractorService/tractor_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common_bottom_sheet.dart';

class AddTractorPage extends StatefulWidget {
  const AddTractorPage({Key? key}) : super(key: key);

  @override
  State<AddTractorPage> createState() => _AddTractorPageState();
}
class _AddTractorPageState extends State<AddTractorPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _purchaseCostController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();

  String _status = "Active";
  DateTime? _purchaseDate;

  final List<String> _statuses = ["Active", "Inactive", "Maintenance"];
  bool _isLoading = false;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
        _purchaseDateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _saveTractor() async {
    if (!_formKey.currentState!.validate()) return;

    final tractorService = TractorService();

    final body = {
      "serialNumber": _serialController.text.trim(),
      "model": _modelController.text.trim(),
      "capacityHp": _capacityController.text.trim(),
      "purchaseDate": _purchaseDate?.toIso8601String(),
      "purchaseCost": _purchaseCostController.text.trim(),
      "status": _status,
    };

    setState(() => _isLoading = true);

    try {
      final response = await tractorService.addTractor(body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Tractor added successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to add tractor (${response.statusCode})"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Tractor",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: colors.text,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel("Serial Number", colors.text),
                  _buildTextField(
                    controller: _serialController,
                    hint: "Enter tractor serial number",
                    validator: (val) => val == null || val.isEmpty
                        ? "Please enter serial number"
                        : null,
                    colors: colors,
                  ),
                  const SizedBox(height: 20),

                  _fieldLabel("Model", colors.text),
                  _buildTextField(
                    controller: _modelController,
                    hint: "Enter tractor model",
                    validator: (val) =>
                    val == null || val.isEmpty ? "Please enter model" : null,
                    colors: colors,
                  ),
                  const SizedBox(height: 20),

                  _fieldLabel("Capacity (HP)", colors.text),
                  _buildTextField(
                    controller: _capacityController,
                    hint: "Enter horsepower (HP)",
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty
                        ? "Please enter capacity"
                        : null,
                    colors: colors,
                  ),
                  const SizedBox(height: 20),

                  _fieldLabel("Purchase Date", colors.text),
                  TextFormField(
                    controller: _purchaseDateController,
                    readOnly: true,
                    onTap: () => _pickDate(context),
                    decoration: _inputDecoration("Select date", colors).copyWith(
                      suffixIcon:
                      Icon(Icons.calendar_today, color: Colors.green.shade600),
                    ),
                    style: TextStyle(color: colors.text),
                    validator: (value) =>
                    value == null || value.isEmpty ? "Please select a date" : null,
                  ),
                  const SizedBox(height: 20),

                  _fieldLabel("Purchase Cost (₹)", colors.text),
                  _buildTextField(
                    controller: _purchaseCostController,
                    hint: "Enter purchase cost",
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty
                        ? "Please enter cost"
                        : null,
                    colors: colors,
                  ),
                  const SizedBox(height: 20),

                  _fieldLabel("Status", colors.text),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: () async {
                        final selected = await CommonBottomSheet.showSelector(
                          context: context,
                          options: _statuses,
                          selectedValue: _status,
                          background: colors.card,
                          textColor: colors.text,
                        );

                        if (selected != null) {
                          setState(() => _status = selected);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_status, style: TextStyle(fontSize: 16, color: colors.text)),
                            Icon(Icons.keyboard_arrow_down, color: Colors.green.shade600),
                          ],
                        ),
                      ),
                    ),
                  ),
                    const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveTractor,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Save Tractor",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        color: color.withOpacity(0.85),
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required AppColors colors,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint, colors),
      style: TextStyle(color: colors.text),
    );
  }

  InputDecoration _inputDecoration(String hint, AppColors colors) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.text.withOpacity(0.5)),
      filled: true,
      fillColor: colors.card,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade600, width: 1.2),
      ),
    );
  }
}
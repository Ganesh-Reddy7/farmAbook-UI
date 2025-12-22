import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/TractorService/tractor_service.dart';
import '../../../theme/app_colors.dart';

class AddClientPage extends StatefulWidget {
  const AddClientPage({Key? key}) : super(key: key);

  @override
  State<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  final _formKey = GlobalKey<FormState>();
  final tractorService = TractorService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? selectedDate;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  void _saveClient() async {
    if (_formKey.currentState!.validate()) {
      final payload = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "notes": _descriptionController.text.trim(),
      };
      try {
        final response = await tractorService.addClient(payload);

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Client added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Failed: ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠ Error: $e"),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
          "Add Client",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: colors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel("Person’s Name", colors.text),
              _buildTextField(
                controller: _nameController,
                hint: "Enter full name",
                validator: (val) =>
                val == null || val.isEmpty ? "Please enter a name" : null,
                colors: colors,
              ),
              const SizedBox(height: 20),

              _fieldLabel("Date", colors.text),
              TextFormField(
                controller: _dateController,
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

              _fieldLabel("Phone Number", colors.text),
              _buildTextField(
                controller: _phoneController,
                hint: "Enter phone number",
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter phone number";
                  if (val.length < 10) return "Invalid phone number";
                  return null;
                },
                colors: colors,
              ),
              const SizedBox(height: 20),

              _fieldLabel("Address (Optional)", colors.text),
              _buildTextField(
                controller: _addressController,
                hint: "Enter address",
                validator: (_) => null,
                colors: colors,
              ),
              const SizedBox(height: 20),

              _fieldLabel("Description (Optional)", colors.text),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration("Write any notes or details", colors),
                style: TextStyle(color: colors.text),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width:double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveClient,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Save Client",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
    );
  }

  // -------------------- Helpers --------------------

  Widget _fieldLabel(String text, Color color) {
    return Padding(
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
  }

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

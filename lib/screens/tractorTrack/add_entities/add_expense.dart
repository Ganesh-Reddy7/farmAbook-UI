import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/Tractor.dart';
import '../../../services/TractorService/tractor_service.dart';
import '../../../theme/app_colors.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({Key? key}) : super(key: key);

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final tractorService = TractorService();

  List<Tractor> tractorNames = [];
  Tractor? _selectedTractor;

  DateTime? _selectedDate;
  String? _selectedExpenseType;

  // Controllers
  final TextEditingController _litresController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _expenseTypes = ["Fuel", "Repair", "Maintenance", "Other"];

  @override
  void dispose() {
    _litresController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedExpenseType = _expenseTypes.first;
    _loadTractors();
  }

  Future<void> _loadTractors() async {
    try {
      final tractors = await tractorService.getTractorList();

      setState(() {
        tractorNames = tractors;

        if (tractorNames.isNotEmpty) {
          _selectedTractor = tractorNames.first;
        }
      });
    } catch (e) {
      debugPrint("Error loading tractors: $e");
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final tractorId = _selectedTractor?.id;
      final date = _selectedDate?.toIso8601String();
      final type = _selectedExpenseType;
      final litres = type == "Fuel" ? double.tryParse(_litresController.text) : 0;
      final amount = double.parse(_amountController.text);
      final notes = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      final payload = {
        "id": 0,
        "tractorId": tractorId,
        "expenseDate": date,
        "type": type,
        "litres": litres,
        "cost": amount,
        "notes": notes,
      };

      try {
        final response = await tractorService.addTractorExpense(payload);
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Expense added successfully!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context, payload);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed: ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
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
      backgroundColor: colors.card,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Expense",
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
              // ---------------- Tractor ----------------
              _fieldLabel("Tractor", colors.text),
              GestureDetector(
                onTap: () async {
                  final selected = await showBottomSheetSelector<Tractor>(
                    context: context,
                    title: "Select Tractor",
                    items: tractorNames,
                    displayText: (t) => t.displayName,
                    selected: _selectedTractor,
                    color: colors.card
                  );

                  if (selected != null) {
                    setState(() => _selectedTractor = selected);
                  }
                },
                child: _dropdownLikeField(
                  value: _selectedTractor?.displayName ?? "Select tractor",
                  colors: colors,
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- Date ----------------
              _fieldLabel("Date", colors.text),
              TextFormField(
                readOnly: true,
                onTap: () => _pickDate(context),
                controller: TextEditingController(
                  text: _selectedDate == null
                      ? ""
                      : DateFormat('dd MMM yyyy').format(_selectedDate!),
                ),
                decoration: _inputDecoration("Select date", colors).copyWith(
                  suffixIcon:
                  Icon(Icons.calendar_today, color: Colors.green.shade600),
                ),
                style: TextStyle(color: colors.text),
                validator: (_) =>
                _selectedDate == null ? "Please select a date" : null,
              ),

              const SizedBox(height: 20),

              // ---------------- Expense Type ----------------
              _fieldLabel("Expense Type", colors.text),
              GestureDetector(
                onTap: () async {
                  final selected = await showBottomSheetSelector<String>(
                    context: context,
                    title: "Select Expense Type",
                    items: _expenseTypes,
                    displayText: (v) => v,
                    selected: _selectedExpenseType,
                      color: colors.card
                  );

                  if (selected != null) {
                    setState(() => _selectedExpenseType = selected);
                  }
                },
                child: _dropdownLikeField(
                  value: _selectedExpenseType ?? "Select type",
                  colors: colors,
                ),
              ),

              // ---------------- Fuel Litres ----------------
              if (_selectedExpenseType == "Fuel") ...[
                const SizedBox(height: 20),
                _fieldLabel("No. of Litres", colors.text),
                _buildTextField(
                  controller: _litresController,
                  hint: "Enter litres",
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (_selectedExpenseType == "Fuel") {
                      if (val == null || val.isEmpty) {
                        return "Please enter litres";
                      }
                      if (double.tryParse(val) == null) {
                        return "Enter valid number";
                      }
                    }
                    return null;
                  },
                  colors: colors,
                ),
              ],

              const SizedBox(height: 20),

              // ---------------- Amount ----------------
              _fieldLabel("Amount (₹)", colors.text),
              _buildTextField(
                controller: _amountController,
                hint: "Enter expense amount",
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Please enter amount";
                  if (double.tryParse(val) == null) return "Enter valid number";
                  return null;
                },
                colors: colors,
              ),
              const SizedBox(height: 20),
              _fieldLabel("Description (Optional)", colors.text),
              _buildTextField(
                controller: _descriptionController,
                hint: "Enter short description",
                colors: colors,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveExpense,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Save Expense",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownLikeField({
    required String value,
    required AppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: colors.text.withOpacity(
                  value.startsWith("Select") ? 0.5 : 1),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.green.shade700),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.9),
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

Future<T?> showBottomSheetSelector<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T) displayText,
  required Color color,
  T? selected,

}) {
  return showModalBottomSheet<T>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: color,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700 , color: Colors.white),
              ),
              const SizedBox(height: 12),

              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final isSelected = item == selected;

                    return ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 4),
                      title: Text(
                        displayText(item),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                          color: Colors.white
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                          color: Colors.green.shade700)
                          : Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

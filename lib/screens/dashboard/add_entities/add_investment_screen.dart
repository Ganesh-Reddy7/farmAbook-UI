import 'dart:ui';
import 'package:farmabook/models/crop.dart';
import 'package:flutter/material.dart';
import '../../../services/investment_service.dart';
import '../../../widgets/FrostedDropDown.dart';
import '../../../widgets/FrostedInput.dart';


class AddInvestmentScreen extends StatefulWidget {
  final Color scaffoldBg;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const AddInvestmentScreen({
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
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  cropDTO? _selectedCrop;
  List<cropDTO> _cropOptions = [];
  DateTime? _selectedDate;
  List<Worker> _workers = [];
  bool _isSaving = false;
  bool _loadingCrops = false;

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    try {
      _cropOptions = await InvestmentService().getCrops(DateTime.now().year);
      setState(() {
        _loadingCrops = false;
      });
    } catch (e) {
      setState(() => _loadingCrops = false);
      print("Failed to fetch crops: $e");
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (var w in _workers) w.dispose();
    super.dispose();
  }

  double get totalWorkerWage {
    double total = 0;
    for (var w in _workers) {
      total += double.tryParse(w.wageController.text) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: widget.scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: widget.primaryText),
          title: Text(
            "Add Investment",
            style: TextStyle(
              color: widget.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          bottom: TabBar(
            labelColor: widget.accent,
            unselectedLabelColor: widget.secondaryText,
            indicatorColor: widget.accent,
            tabs: const [
              Tab(text: "Single Investment"),
              Tab(text: "With Workers"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Single Investment
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDateField(),
                  const SizedBox(height: 12),
                  FrostedInput(
                    label: "Amount (₹)",
                    icon: Icons.currency_rupee,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                  FrostedDropdown(
                    label: "Select Crop",
                    icon: Icons.agriculture,
                    options: _cropOptions.map((c) => c.cropName).toList(),
                    selectedValue: _selectedCrop?.cropName,
                    onChanged: (value) {
                      setState(() {
                        _selectedCrop = _cropOptions.firstWhere((c) => c.cropName == value);;
                      });
                    },
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                  _buildFrostedInput("Description", Icons.note, _descriptionController, maxLines: 2, compact: true),
                  const SizedBox(height: 24),
                  _buildSaveButton(isSingle: true),
                ],
              ),
            ),

            // Investment with Workers
            SingleChildScrollView(
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
                        _selectedCrop = _cropOptions.firstWhere((c) => c.cropName == value);;
                      });
                    },
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                  _buildFrostedInput("Description", Icons.note, _descriptionController, maxLines: 2, compact: true),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _workers.length,
                    itemBuilder: (context, index) {
                      final worker = _workers[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  widget.cardGradientStart.withOpacity(0.3),
                                  widget.cardGradientEnd.withOpacity(0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: widget.cardBorder, width: 1),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: _buildFrostedTextField(
                                        controller: worker.nameController,
                                        label: "Worker Name",
                                        icon: Icons.person,
                                        compact: true,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => setState(() => _workers.removeAt(index)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Flexible(
                                      child: _buildFrostedTextField(
                                        controller: worker.wageController,
                                        label: "Wage (₹)",
                                        icon: Icons.currency_rupee,
                                        keyboardType: TextInputType.number,
                                        compact: true,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: _buildFrostedTextField(
                                        controller: worker.roleController,
                                        label: "Role",
                                        icon: Icons.badge,
                                        compact: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                  ,
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _workers.add(Worker())),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Worker"),
                  ),
                  const SizedBox(height: 12),
                    if (_workers.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Total Wage: ₹${totalWorkerWage.toStringAsFixed(2)}",
                        style: TextStyle(color: widget.primaryText, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildSaveButton(isSingle: false),
                ],
              ),
            ),
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

  Widget _buildFrostedInput(String label, IconData icon, TextEditingController controller,
      {int maxLines = 1, bool readOnly = false, VoidCallback? onTap, bool compact = false}) {
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
            readOnly: readOnly,
            maxLines: maxLines,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: compact ? 13 : 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
              labelText: label,
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: compact ? 13 : 15),
              border: InputBorder.none,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool compact = false,
  }) {
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
            keyboardType: keyboardType,
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

  Widget _buildSaveButton({required bool isSingle}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isSaving ? null : _saveInvestment,
        child: _isSaving
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Text("Save Investment"),
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

  void _saveInvestment() async {
    if (_selectedDate == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill date and description")),
      );
      return;
    }

    if (_workers.isEmpty && _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter amount or add workers")),
      );
      return;
    }

    setState(() => _isSaving = true);
    final service = InvestmentService();
    bool success = false;

    if (_workers.isEmpty) {
      final amount = double.tryParse(_amountController.text) ?? 0;

      success = await service.saveInvestment(
        amount: amount,
        description: _descriptionController.text,
        date: _selectedDate!,
        cropId: _selectedCrop!.cropId,
      );
    } else {
      final workerData = _workers.map((w) => w.toMap()).toList();
      success = await service.saveInvestmentWithWorkers(
        description: _descriptionController.text,
        date: _selectedDate!,
        workers: workerData,
        cropId: _selectedCrop!.cropId,
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Investment Saved!"), backgroundColor: widget.accent),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save investment."), backgroundColor: Colors.redAccent),
      );
    }
  }

}

class Worker {
  TextEditingController nameController = TextEditingController();
  TextEditingController wageController = TextEditingController();
  TextEditingController roleController = TextEditingController();

  void dispose() {
    nameController.dispose();
    wageController.dispose();
    roleController.dispose();
  }

  Map<String, dynamic> toMap() => {
    "name": nameController.text,
    "wage": wageController.text,
    "role": roleController.text,
  };
}

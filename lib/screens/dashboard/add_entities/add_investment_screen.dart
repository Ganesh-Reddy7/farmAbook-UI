import 'package:flutter/material.dart';
import 'package:farmabook/models/crop.dart';
import '../../../services/investment_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/IndianCurrencyFormatter.dart';
import '../../../widgets/FrostedInput.dart';
import '../../../widgets/FrostedDropDown.dart';
import '../../../widgets/commonDateSelector.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({Key? key}) : super(key: key);

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();

  DateTime? _selectedDate;
  cropDTO? _selectedCrop;
  List<cropDTO> _cropOptions = [];

  final List<Worker> _workers = [];
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
    _dateCtrl.dispose();
    for (final w in _workers) {
      w.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchCrops() async {
    _cropOptions = await InvestmentService().getCrops(DateTime.now().year);
    setState(() {});
  }

  // ---------------- CALCULATIONS ----------------

  double get totalWorkerWage {
    return _workers.fold<double>(
      0,
          (sum, w) {
        final raw = w.wageController.text.replaceAll(',', '');
        final value = double.tryParse(raw) ?? 0;
        return sum + value;
      },
    );
  }


  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.card,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Add Investment",
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: colors.accent,
            unselectedLabelColor: colors.secondaryText,
            indicatorColor: colors.accent,
            tabs: const [
              Tab(text: "Single Investment"),
              Tab(text: "With Workers"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _singleInvestmentTab(colors),
            _workersInvestmentTab(colors),
          ],
        ),
      ),
    );
  }

  // ---------------- SINGLE INVESTMENT ----------------

  Widget _singleInvestmentTab(AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _dateField(),
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
          _cropDropdown(),
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
    );
  }

  // ---------------- WITH WORKERS ----------------

  Widget _workersInvestmentTab(AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _dateField(),
          const SizedBox(height: 12),
          _cropDropdown(),
          const SizedBox(height: 12),

          FrostedInput(
            label: "Description",
            icon: Icons.note,
            controller: _descCtrl,
            maxLines: 2,
            compact: true,
          ),

          const SizedBox(height: 12),

          ..._workers.map(_workerCard),

          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => setState(
                  () => _workers.add(Worker(onUpdate: () => setState(() {}))),
            ),
            icon: const Icon(Icons.add),
            label: const Text("Add Worker"),
          ),

          if (_workers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Total Wage: ₹${IndianCurrencyFormatter.format(totalWorkerWage.toString())}",
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),
          _saveButton(colors),
        ],
      ),
    );
  }

  // ---------------- COMMON WIDGETS ----------------

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

  Widget _cropDropdown() {
    return FrostedDropdown(
      label: "Select Crop",
      icon: Icons.agriculture,
      options: _cropOptions.map((c) => c.cropName).toList(),
      selectedValue: _selectedCrop?.cropName,
      compact: true,
      onChanged: (v) => setState(
            () => _selectedCrop =
            _cropOptions.firstWhere((c) => c.cropName == v),
      ),
    );
  }
  Widget _workerCard(Worker worker) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.divider.withOpacity(0.6),
        ),
      ),
      child: Column(
        children: [
          // ---------- NAME + DELETE ----------
          Row(
            children: [
              Expanded(
                child: FrostedInput(
                  label: "Worker Name",
                  icon: Icons.person,
                  controller: worker.nameController,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => setState(() => _workers.remove(worker)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ---------- WAGE + ROLE ----------
          Row(
            children: [
              Expanded(
                child: FrostedInput(
                  label: "Wage (₹)",
                  icon: Icons.currency_rupee,
                  controller: worker.wageController,
                  keyboardType: TextInputType.number,
                  compact: true,
                  onChanged: _currencyFormatter(
                    worker.wageController,
                    onDone: () => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FrostedInput(
                  label: "Role",
                  icon: Icons.badge,
                  controller: worker.roleController,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _saveButton(AppColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveInvestment,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Save Investment"),
      ),
    );
  }

  // ---------------- LOGIC ----------------

  Future<void> _pickDate() async {
    final picked = await CommonDateSelector.show(
      context: context,
      title: "Select Investment Date",
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

  ValueChanged<String> _currencyFormatter(
      TextEditingController controller, {
        VoidCallback? onDone,
      }) {
    return (value) {
      final raw = value.replaceAll(',', '');
      if (raw.isEmpty) return;

      final number = double.tryParse(raw);
      if (number == null) return;

      final formatted = IndianCurrencyFormatter.format(raw);

      if (formatted != value) {
        controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
        onDone?.call();
      }
    };
  }


  Future<void> _saveInvestment() async {
    if (_selectedDate == null ||
        _selectedCrop == null ||
        _descCtrl.text.isEmpty) {
      _showSnack("Please fill all required fields");
      return;
    }

    if (_workers.isEmpty && _amountCtrl.text.isEmpty) {
      _showSnack("Enter amount or add workers");
      return;
    }

    setState(() => _isSaving = true);

    final service = InvestmentService();
    bool success;

    if (_workers.isEmpty) {
      success = await service.saveInvestment(
        amount:
        double.parse(_amountCtrl.text.replaceAll(',', '')),
        description: _descCtrl.text,
        date: _selectedDate!,
        cropId: _selectedCrop!.cropId,
      );
    } else {
      success = await service.saveInvestmentWithWorkers(
        description: _descCtrl.text,
        date: _selectedDate!,
        cropId: _selectedCrop!.cropId,
        workers: _workers.map((w) => w.toMap()).toList(),
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      _showSnack("Failed to save investment");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ---------------- WORKER MODEL ----------------

class Worker {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController wageController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  final VoidCallback onUpdate;

  Worker({required this.onUpdate});

  void dispose() {
    nameController.dispose();
    wageController.dispose();
    roleController.dispose();
  }

  Map<String, dynamic> toMap() => {
    "name": nameController.text,
    "wage": double.tryParse(
      wageController.text.replaceAll(',', ''),
    ) ??
        0,
    "role": roleController.text,
  };
}


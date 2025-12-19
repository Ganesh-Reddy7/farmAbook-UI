import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../services/crop_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/FrostedInput.dart';
import '../../../widgets/commonDateSelector.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({Key? key,}) : super(key: key);

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _plantedDate;
  bool _isSaving = false;
  String? _dateError;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickPlantedDate() async {
    final picked = await CommonDateSelector.show(
      context: context,
      title: "Select Planted Date",
      initialDate: _plantedDate ?? DateTime.now(),
      minDate: DateTime(DateTime.now().year - 5),
      maxDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _plantedDate = picked;
        _dateError = null;
        _dateController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveCrop() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_plantedDate == null) {
      setState(() {
        _dateError = "Please select planted date";
      });
      return;
    }

    final area = double.tryParse(_areaController.text.trim());
    if (area == null || area <= 0) {
      _showError("Enter valid area");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await CropService().addCrop(
        name: _nameController.text.trim(),
        area: area,
        plantedDate: _plantedDate!,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
      } else {
        _showError("Failed to add crop");
      }
    } catch (e) {
      log("AddCropScreen error: $e");
      if (mounted) _showError("Something went wrong");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryText),
        title: Text(
          "Add Crop",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colors.primaryText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FrostedInput(
                label: "Crop Name",
                icon: Icons.agriculture,
                controller: _nameController,
                compact: true,
              ),
              const SizedBox(height: 12),
              FrostedInput(
                label: "Area (in Acres)",
                icon: Icons.calculate,
                controller: _areaController,
                keyboardType: TextInputType.number,
                compact: true,
              ),
              const SizedBox(height: 12),
              FrostedInput(
                label: "Planted Date",
                icon: Icons.calendar_today,
                controller: _dateController,
                readOnly: true,
                onTap: _pickPlantedDate,
                compact: true,
              ),

              if (_dateError != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _dateError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCrop,
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
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text("Add Crop",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
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
}

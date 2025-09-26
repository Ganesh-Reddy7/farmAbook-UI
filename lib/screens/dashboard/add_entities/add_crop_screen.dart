import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../services/crop_service.dart';
import '../../../widgets/FrostedInput.dart';

class AddCropScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const AddCropScreen({
    Key? key,
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.scaffoldBg,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
  }) : super(key: key);

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  DateTime? _plantedDate;
  bool _isSaving = false;

  void _saveCrop() async {
    if (!_formKey.currentState!.validate() || _plantedDate == null) return;

    setState(() => _isSaving = true);

    try {
      log("GKaaxx :: $_nameController . $_valueController , $_plantedDate");
      final success = await CropService().addCrop(
        name: _nameController.text.trim(),
        area: double.parse(_valueController.text.trim()),
        plantedDate: _plantedDate!,
      );

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add crop")),
        );
      }
    } catch (e) {
      log("AddCropScreen exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickPlantedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );

    if (picked != null) setState(() => _plantedDate = picked);
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
          "Add Crop",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: widget.primaryText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FrostedInput(
                label: "Crop Name",
                icon: Icons.agriculture,
                controller: _nameController,
                compact: true,
              ),
              const SizedBox(height: 12),
              FrostedInput(
                label: "Enter Area in Acre",
                icon: Icons.calculate,
                controller: _valueController,
                keyboardType: TextInputType.number,
                compact: true,
              ),
              const SizedBox(height: 12),
              FrostedInput(
                label: "Select Date",
                icon: Icons.calendar_today,
                controller: TextEditingController(
                  text: _plantedDate != null
                      ? "${_plantedDate!.year}-${_plantedDate!.month.toString().padLeft(2,'0')}-${_plantedDate!.day.toString().padLeft(2,'0')}"
                      : "",
                ),
                readOnly: true,
                onTap: _pickPlantedDate,
                compact: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveCrop,
                  child: _isSaving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text("Add Crop"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

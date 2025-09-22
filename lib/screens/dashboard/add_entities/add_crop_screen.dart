import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../models/crop.dart';
import '../../../services/crop_service.dart';

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
        title: const Text("Add Crop",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: widget.primaryText),
                decoration: InputDecoration(
                  labelText: "Crop Name",
                  labelStyle: TextStyle(color: widget.secondaryText),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? "Enter crop name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                style: TextStyle(color: widget.primaryText),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Value",
                  labelStyle: TextStyle(color: widget.secondaryText),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? "Enter crop value" : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickPlantedDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: widget.cardBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _plantedDate == null
                        ? "Select Planted Date"
                        : "${_plantedDate!.year}-${_plantedDate!.month.toString().padLeft(2,'0')}-${_plantedDate!.day.toString().padLeft(2,'0')}",
                    style: TextStyle(
                        color: _plantedDate == null ? widget.secondaryText : widget.primaryText),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
                onPressed: _isSaving ? null : _saveCrop,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Crop"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

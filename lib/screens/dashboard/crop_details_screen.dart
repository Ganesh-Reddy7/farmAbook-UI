import 'package:flutter/material.dart';
import '../../../models/crop.dart';
import '../../services/crop_service.dart';

class CropDetailScreen extends StatefulWidget {
  final Crop crop;
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;
  final VoidCallback? onUpdate;

  const CropDetailScreen({
    Key? key,
    required this.crop,
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.scaffoldBg,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  late Crop crop;

  @override
  void initState() {
    super.initState();
    crop = widget.crop;
  }

  void _updateCropValue(double newValue) async {
    try {
      final updated = await CropService().updateCropValue(crop.id, newValue);
      setState(() {
        crop = updated!;
      });
      widget.onUpdate?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Updated crop value to ₹${newValue.toStringAsFixed(0)}"),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update crop value"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text(crop.name,
            style: TextStyle(
                color: widget.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${crop.name}",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryText)),
            const SizedBox(height: 8),
            Text("Planted Date: ${crop.plantedDate}",
                style: TextStyle(fontSize: 14, color: widget.secondaryText)),
            const SizedBox(height: 8),
            Text("Value: ₹${crop.value?.toStringAsFixed(0)}",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.accent)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
              onPressed: () {
                _showUpdateValueDialog();
              },
              child: const Text("Update Value"),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateValueDialog() {
    final controller = TextEditingController(text: crop.value?.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Crop Value"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Value"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                Navigator.pop(context);
                _updateCropValue(newValue);
              }
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }
}

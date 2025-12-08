import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/Tractor.dart';
import '../../../services/TractorService/tractor_service.dart';

class AddReturnPage extends StatefulWidget {
  final int? clientId;
  final String? clientName;

  const AddReturnPage({Key? key, this.clientId, this.clientName})
      : super(key: key);

  @override
  State<AddReturnPage> createState() => _AddReturnPageState();
}

class _AddReturnPageState extends State<AddReturnPage> {
  final _formKey = GlobalKey<FormState>();
  final tractorService = TractorService();

  List<Tractor> tractorList = [];
  Tractor? _selectedTractor;

  DateTime? _selectedDate = DateTime.now();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaTripsController = TextEditingController();
  final TextEditingController _earnedController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTractors();

    // If clientName was passed, prefill the name controller (but we will hide the field)
    if (widget.clientName != null) {
      _nameController.text = widget.clientName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaTripsController.dispose();
    _earnedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTractors() async {
    try {
      final tractors = await tractorService.getTractorList();
      setState(() {
        tractorList = tractors;
        if (tractorList.isNotEmpty && _selectedTractor == null) {
          _selectedTractor = tractorList.first;
        }
      });
    } catch (e) {
      debugPrint("Error loading tractors: $e");
      // optional: show snackbar
    }
  }

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _endTime = t);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Future<void> _saveReturn() async {
    if (_isSubmitting) return;

    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for times
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start time')),
      );
      return;
    }
    if (_endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end time')),
      );
      return;
    }

    // If clientId not passed, ensure name provided
    if (widget.clientId == null && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the worker / client name')),
      );
      return;
    }

    // Prepare payload
    final payload = {
      "tractorId": _selectedTractor?.id,
      "activityDate": _selectedDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(_selectedDate!),
      "startTime": _formatTimeOfDay(_startTime!),
      "endTime": _formatTimeOfDay(_endTime!),
      "clientName": widget.clientName ?? _nameController.text.trim(),
      "acresWorked": double.tryParse(_areaTripsController.text) ?? 0.0,
      "amountEarned": double.tryParse(_earnedController.text) ?? 0.0,
      "notes": _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      "clientId": widget.clientId ?? null,
      // farmerId will be appended by service (if your service does so)
    };

    debugPrint("📤 Add Return Payload: $payload");

    setState(() => _isSubmitting = true);

    try {
      final response = await tractorService.addReturn(payload);
      debugPrint("📥 Add Return Response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Return added successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Return payload to previous screen (caller can refresh list)
        Navigator.pop(context, payload);
      } else {
        // Show server error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add return: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error adding return: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = _AppColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Add Return",
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tractor Picker
              _fieldLabel("Tractor", colors.text),
              GestureDetector(
                onTap: () async {
                  final selected = await showBottomSheetSelector<Tractor>(
                    context: context,
                    title: "Select Tractor",
                    items: tractorList,
                    displayText: (t) => t.displayName,
                    selected: _selectedTractor,
                    color: colors.background,
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

              // Name / Worked With (hide if client passed in)
              if (widget.clientId == null) ...[
                _fieldLabel("Worked With / Name", colors.text),
                _buildTextField(
                  controller: _nameController,
                  hint: "Enter name",
                  validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
                  colors: colors,
                ),
                const SizedBox(height: 20),
              ],

              // Date Picker (native)
              _fieldLabel("Date", colors.text),
              GestureDetector(
                onTap: _pickDate,
                child: _dropdownLikeField(
                  value: _selectedDate == null
                      ? "Select date"
                      : DateFormat('dd MMM yyyy').format(_selectedDate!),
                  colors: colors,
                ),
              ),

              const SizedBox(height: 20),

              // Start Time & End Time (side-by-side)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("Start Time", colors.text),
                        GestureDetector(
                          onTap: _pickStartTime,
                          child: _dropdownLikeField(
                            value: _startTime == null
                                ? "Select start time"
                                : _formatTimeOfDay(_startTime!),
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("End Time", colors.text),
                        GestureDetector(
                          onTap: _pickEndTime,
                          child: _dropdownLikeField(
                            value: _endTime == null
                                ? "Select end time"
                                : _formatTimeOfDay(_endTime!),
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Acres / Trips
              _fieldLabel("Acres/Trips", colors.text),
              _buildTextField(
                controller: _areaTripsController,
                hint: "Enter acres or number of trips",
                validator: (v) =>
                v == null || v.isEmpty ? "Enter value" : null,
                keyboardType: TextInputType.number,
                colors: colors,
              ),

              const SizedBox(height: 20),

              // Earned Amount
              _fieldLabel("Earned Amount (₹)", colors.text),
              _buildTextField(
                controller: _earnedController,
                hint: "Enter earned amount",
                validator: (v) => v == null || v.isEmpty ? "Enter amount" : null,
                keyboardType: TextInputType.number,
                colors: colors,
              ),

              const SizedBox(height: 20),

              // Description
              _fieldLabel("Description (Optional)", colors.text),
              _buildTextField(
                controller: _descriptionController,
                hint: "Enter description",
                colors: colors,
              ),

              const SizedBox(height: 30),

              // Save Button (full width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isSubmitting ? Colors.green.shade200 : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Save Return",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
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
    required _AppColors colors,
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
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: value.startsWith("Select")
                    ? colors.text.withOpacity(0.5)
                    : colors.text,
                overflow: TextOverflow.ellipsis,
              ),
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
    required _AppColors colors,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.text),
      decoration: InputDecoration(
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
    backgroundColor: color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 16),

              Text(title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
              const SizedBox(height: 12),

              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final isSelected = item == selected;

                    return ListTile(
                      title: Text(
                        displayText(item),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                          color: Colors.green.shade600)
                          : Icon(Icons.chevron_right,
                          color: Colors.white.withOpacity(0.6)),
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
class _AppColors {
  final Color background;
  final Color card;
  final Color text;

  _AppColors(bool isDark)
      : background =
  isDark ? const Color(0xFF081712) : const Color(0xFFFDFDFD),
        card = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3),
        text = isDark ? Colors.white : const Color(0xFF1A1A1A);
}

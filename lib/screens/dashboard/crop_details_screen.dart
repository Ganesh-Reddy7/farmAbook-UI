import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crop.dart';
import '../../models/investment.dart';
import '../../models/return_model.dart';
import '../../services/crop_service.dart';
import '../../services/return_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/barChart.dart';
import '../../widgets/frosted_button.dart';
import '../../widgets/sectionTitle.dart';


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
enum CropTab { investments, returns }
class _CropDetailScreenState extends State<CropDetailScreen> {
  late Crop crop;
  CropTab selectedTab = CropTab.investments;
  List<Investment> investments = [];
  List<ReturnDetailModel> returnsData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    crop = widget.crop;
    _fetchCropDetails();

  }

  Future<void> _fetchCropDetails() async {
    try {
      final inv = await CropService().getCropInvestmentByYear(date:crop.plantedDate, cropId:crop.id);
      final ret = await ReturnService().getReturnsByCropAndYear(cropId:crop.id , year:crop.plantedDate!.year,);
      setState(() {
        investments = inv;
        returnsData = ret;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _updateCropValue(double newValue) async {
    try {
      final updated = await CropService().updateCropValue(crop.id, newValue);
      setState(() => crop = updated!);
      widget.onUpdate?.call();
    } catch (e) {}
  }

  void _updateCropArea(double newArea) async {
    // try {
    //   final updated = await CropService().updateCropArea(crop.id, newArea);
    //   setState(() => crop = updated!);
    //   widget.onUpdate?.call();
    // } catch (e) {}
  }

  void _showUpdateDialog({required bool isArea}) {
    final controller = TextEditingController(
        text: isArea ? crop.area.toStringAsFixed(1) : crop.value?.toStringAsFixed(0));
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(isArea ? "Update Area" : "Update Quantity"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: isArea ? "Area" : "Quantity"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () {
                  final newValue = double.tryParse(controller.text);
                  if (newValue != null) {
                    Navigator.pop(context);
                    isArea ? _updateCropArea(newValue) : _updateCropValue(newValue);
                  }
                },
                child: const Text("Update"))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text(
          crop.name,
          style: TextStyle(
            color: widget.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌱 Crop Info Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.cardBorder),
                gradient: LinearGradient(
                  colors: [widget.cardGradientStart, widget.cardGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
                child: Column(
                  children: [
                    // First Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.agriculture,
                            label: "Crop",
                            value: crop.name,
                            color: widget.primaryText,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.date_range,
                            label: "Planted",
                            value:
                            "${crop.plantedDate?.year}-${crop.plantedDate?.month.toString().padLeft(2, '0')}-${crop.plantedDate?.day.toString().padLeft(2, '0')}",
                            color: widget.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Second Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.square_foot,
                            label: "Area",
                            value: crop.area.toStringAsFixed(1),
                            color: widget.accent,
                            onTap: () => _showUpdateDialog(isArea: true),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.inventory_2,
                            label: "Quantity",
                            value: crop.value?.toStringAsFixed(0) ?? "0",
                            color: widget.accent,
                            onTap: () => _showUpdateDialog(isArea: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Third Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.money_off,
                            label: "Investment",
                            value: "₹${crop.totalInvested?.toStringAsFixed(0) ?? '0'}",
                            color: Colors.redAccent,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.trending_up,
                            label: "Returns",
                            value: "₹${crop.totalReturns?.toStringAsFixed(0) ?? '0'}",
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ),

            const SizedBox(height: 28),
            SectionTitle(title: "Investment vs Returns", isDark: isDark , fontSize:16),
            // 🥧 Pie Chart Section
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.cardGradientStart.withOpacity(0.05),
                border: Border.all(color: widget.cardBorder),
              ),
              child: SizedBox(height: 220, child: _buildPieChart()),
            ),

            const SizedBox(height: 32),
            SectionTitle(title: "Area vs Quantity", isDark: isDark , fontSize:16),
            const SizedBox(height: 16),
            CommonBarChart(
              isDark: isDark,
              chartBg: colors.card,
              labels: ["Area" , "Quantity"],
              values: [crop.area , ?crop?.value],
              barColor: Colors.green,
              barWidth: 16,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FrostedButton(
                    label: "Investments",
                    icon: Icons.money_off,
                    color: selectedTab == CropTab.investments
                        ? Colors.redAccent
                        : Colors.redAccent.withOpacity(0.5),
                    onTap: () {
                      setState(() => selectedTab = CropTab.investments);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FrostedButton(
                    label: "Returns",
                    icon: Icons.trending_up,
                    color: selectedTab == CropTab.returns
                        ? Colors.green
                        : Colors.green.withOpacity(0.5),
                    onTap: () {
                      setState(() => selectedTab = CropTab.returns);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedTab == CropTab.investments)
              _buildInvestmentList()
            else
              _buildReturnsList(),
          ],
        ),
      ),
    );

  }

  Widget _buildPieChart() {
    final invested = (crop.totalInvested ?? 0).toDouble();
    final returns = (crop.totalReturns ?? 0).toDouble();

    if (invested + returns == 0) {
      return Center(
          child: Text("No data", style: TextStyle(color: widget.secondaryText)));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: invested,
            color: Colors.redAccent,
            title: "Investment\n₹${invested.toInt()}",
            radius: 70,
            titleStyle: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          PieChartSectionData(
            value: returns,
            color: Colors.green,
            title: "Returns\n₹${returns.toInt()}",
            radius: 70,
            titleStyle: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.cardGradientStart.withOpacity(0.1),
          border: Border.all(color: widget.cardBorder.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (investments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text("No investments found",
            style: TextStyle(color: widget.secondaryText)),
      );
    }

    final grouped = groupByMonth<Investment>(
      investments,
          (inv) => inv.date, // assuming `date` is String
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final month = entry.key;
        final monthItems = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryText,
                ),
              ),
            ),
            ...monthItems.map((inv) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
                color: widget.cardGradientStart.withOpacity(0.08),
              ),
              child: ListTile(
                leading: Icon(Icons.money_off,
                    color: Colors.redAccent.withOpacity(0.8)),
                title: Text(
                  inv.description ?? "No description",
                  style: TextStyle(
                      color: widget.primaryText,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                "Date: ${inv.date?.toLocal().toString().split(' ').first}",
                style: TextStyle(
                      color: widget.secondaryText, fontSize: 12),
                ),
                trailing: Text(
                  "₹${(inv.amount ?? 0).toString()}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
            ))
          ],
        );
      }).toList(),
    );
  }

  Widget _buildReturnsList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (investments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text("No investments found",
            style: TextStyle(color: widget.secondaryText)),
      );
    }

    final grouped = groupByMonth<ReturnDetailModel>(
      returnsData,
          (inv) => inv.date, // assuming `date` is String
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final month = entry.key;
        final monthItems = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryText,
                ),
              ),
            ),
            ...monthItems.map((inv) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
                color: widget.cardGradientStart.withOpacity(0.08),
              ),
              child: ListTile(
                leading: Icon(Icons.trending_up, color: Colors.green.withOpacity(0.8)),
                title: Text(
                  inv.description ?? "No description",
                  style: TextStyle(
                    color: widget.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "${inv.date?.toLocal().toString().split(' ').first}    ⚖️ Quantity: ${inv.quantity ?? 0}",
                  style: TextStyle(color: widget.secondaryText, fontSize: 12),
                ),
                trailing: Text(
                  "₹${inv.amount ?? 0}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ),

            ))
          ],
        );
      }).toList(),
    );
  }

  Map<String, List<T>> groupByMonth<T>(
      List<T> items,
      DateTime? Function(T) getDate,
      ) {
    final Map<String, List<T>> grouped = {};

    for (var item in items) {
      final date = getDate(item);
      if (date == null) continue;

      final key = "${_monthName(date.month)} ${date.year}";
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped;
  }

  String _monthName(int month) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[month - 1];
  }



}

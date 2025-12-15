import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crop.dart';
import '../../services/crop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/barChart.dart';
import '../../widgets/commonLineChart.dart';
import '../../widgets/common_bottom_sheet_selector.dart';
import '../../widgets/sectionTitle.dart';
import 'add_entities/add_crop_screen.dart';
import 'crop_details_screen.dart';

class CropsScreen extends StatefulWidget {
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color scaffoldBg;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;

  const CropsScreen({
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.scaffoldBg,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
    Key? key,
  }) : super(key: key);

  @override
  _CropsScreenState createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  int _selectedYear = DateTime.now().year;
  bool _isLineChart = true;

  Map<int, List<Crop>> cropsByYear = {};
  List<double> chartInvestments = [];
  List<double> chartReturns = [];
  List<String> cropList = [];
  bool isChartLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCropsForYear(_selectedYear);
  }

  Future<void> _fetchCropsForYear(int year) async {
    setState(() => isChartLoading = true);

    final fetched = await CropService().getCropsByYear(year);

    chartInvestments = fetched.map((c) => c.totalInvested).toList();
    chartReturns = fetched.map((c) => c.totalReturns).toList();
    cropList = fetched.map((c) => c.name).toList();

    setState(() {
      cropsByYear[year] = fetched;
      isChartLoading = false;
    });
  }


  Future<void> _refreshCurrentYearCrops() async {
    await _fetchCropsForYear(_selectedYear);
  }

  double safeMaxY(double value) => value > 0 ? value * 1.2 : 1000;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);
    final currentYearCrops = cropsByYear[_selectedYear] ?? [];
    final totalArea = currentYearCrops.fold<double>(0, (sum, c) => sum + c.area);
    final totalQty = currentYearCrops.fold<double>(0, (sum, c) => sum + (c.value ?? 0));

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.primaryText),
        title: Text("Crops",
            style: TextStyle(
                color: widget.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(_isLineChart ?  Icons.show_chart : Icons.bar_chart, color: widget.accent),
            onPressed: () => setState(() => _isLineChart = !_isLineChart),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCurrentYearCrops,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if(_isLineChart)
                CommonBarChart(
                  isDark: isDark,
                  chartBg: colors.card,
                  labels: cropList,
                  values: chartInvestments,
                  values2: chartReturns,
                  legend1: "Total Investment",
                  legend2: "Total Returns",
                  barColor2: Colors.green,
                  barColor: Colors.orange,
                  barWidth: 16,
                  isLoading: isChartLoading,
                )
              else
                CommonLineChart(
                  isDark: isDark,
                  labels: cropList,
                  values: chartInvestments,
                  values2: chartReturns,
                  legend1: "Total Investment",
                  legend2: "Total Returns",
                  lineColor1: widget.accent,
                  lineColor2: Colors.orangeAccent,
                ),
              const SizedBox(height: 12),
              Divider(color: colors.divider),
              const SizedBox(height: 12),
              // -------------------- Year Selector --------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionTitle(title: "Select Year:", isDark: isDark , fontSize:16),
                  GestureDetector(
                    onTap: () async {
                      final years = List.generate(5, (i) => DateTime.now().year - i);
                      final selectedYear = await CommonBottomSheetSelector.show<int>(
                        context: context,
                        title: "Select Year",
                        items: years,
                        displayText: (year) => year.toString(),
                        backgroundColor: colors.card,
                        textColor: widget.primaryText,
                        selected: _selectedYear,
                      );

                      if (selectedYear != null) {
                        setState(() => _selectedYear = selectedYear);
                        _fetchCropsForYear(selectedYear);
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          _selectedYear.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_drop_down,
                          color: widget.primaryText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _totalAreaQuantityCard(totalArea, totalQty),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.cardGradientStart.withOpacity(0.05),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: SizedBox(
                  height: 220,
                  child: currentYearCrops.isEmpty
                      ? Center(
                    child:SectionTitle(title: "No pie chart data available", isDark: isDark , fontSize:16),
                  )
                      : PieChart(
                    PieChartData(
                      sections: currentYearCrops.map((crop) {
                        final percentage = totalArea > 0
                            ? (crop.area / totalArea) * 100
                            : 0.0;
                        return PieChartSectionData(
                          value: crop.area,
                          color: _getColorForCrop(crop),
                          title:
                          "${crop.name}\n${crop.area.toStringAsFixed(1)} ha\n${percentage.toStringAsFixed(1)}%",
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              currentYearCrops.isEmpty
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.cardGradientStart.withOpacity(0.1),
                      widget.cardGradientEnd.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: widget.cardBorder.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 40, color: widget.accent),
                    const SizedBox(height: 12),
                    SectionTitle(title: "No crops available", isDark: isDark , fontSize:16),
                    const SizedBox(height: 6),
                    Text(
                      "Please add crops to view details.",
                      style: TextStyle(color: widget.secondaryText),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: currentYearCrops.length,
                itemBuilder: (context, index) {
                  final crop = currentYearCrops[index];
                  return _buildCropCard(crop);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        heroTag: "add-crop",
        backgroundColor: widget.accent,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddCropScreen(
                scaffoldBg: widget.scaffoldBg,
                primaryText: widget.primaryText,
                secondaryText: widget.secondaryText,
                accent: widget.accent,
                cardGradientStart: widget.cardGradientStart,
                cardGradientEnd: widget.cardGradientEnd,
                cardBorder: widget.cardBorder,
              ),
            ),
          );
          if (result == true) _refreshCurrentYearCrops();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // -------------------- Build Crop Card --------------------
  Widget _buildCropCard(Crop crop) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CropDetailScreen(
              crop: crop,
              accent: widget.accent,
              primaryText: widget.primaryText,
              secondaryText: widget.secondaryText,
              scaffoldBg: widget.scaffoldBg,
              cardGradientStart: widget.cardGradientStart,
              cardGradientEnd: widget.cardGradientEnd,
              cardBorder: widget.cardBorder,
              onUpdate: _refreshCurrentYearCrops,
            ),
          ),
        );
        if (result == true) _refreshCurrentYearCrops();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.cardGradientStart.withOpacity(0.0),
              widget.cardGradientEnd.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: widget.cardBorder.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(crop.name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryText)),
                ),
                Text(
                    "${crop.plantedDate?.year}-${crop.plantedDate?.month.toString().padLeft(2, '0')}-${crop.plantedDate?.day.toString().padLeft(2, '0')}",
                    style: TextStyle(
                        fontSize: 13, color: widget.secondaryText)),
                const SizedBox(width: 10),
                Text("Area: ${crop.area.toStringAsFixed(1)}",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.accent)),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Qty: ${crop.value?.toStringAsFixed(0) ?? '0'}",
                    style: TextStyle(
                        fontSize: 13, color: widget.primaryText)),
                Text(
                    "Investment: ₹${crop.totalInvested?.toStringAsFixed(0) ?? '0'}",
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent)),
                Text(
                    "Returns: ₹${crop.totalReturns?.toStringAsFixed(0) ?? '0'}",
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalAreaQuantityCard(double totalArea, double totalQty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            widget.cardGradientStart.withOpacity(0.1),
            widget.cardGradientEnd.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: widget.cardBorder.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _areaQuantityColumn(
            icon: Icons.landscape,
            iconBg: widget.accent.withOpacity(0.2),
            amount: totalArea,
            title: "Total Area",
            amountSuffix: "ha",
            amountColor: widget.accent,
          ),
          Container(
            width: 1,
            height: 60,
            color: widget.cardBorder.withOpacity(0.3),
          ),
          _areaQuantityColumn(
            icon: Icons.inventory_2,
            iconBg: Colors.orange.withOpacity(0.2),
            amount: totalQty,
            title: "Total Quantity",
            amountSuffix: "",
            amountColor: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Column _areaQuantityColumn({
    required IconData icon,
    required Color iconBg,
    required double amount,
    required String title,
    required Color amountColor,
    String amountSuffix = "",
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: amountColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: widget.secondaryText)),
        const SizedBox(height: 4),
        Text(
          "${amount.toStringAsFixed(amountSuffix.isNotEmpty ? 1 : 0)} $amountSuffix",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }


  Color _getColorForCrop(Crop crop) {
    final index = cropsByYear[_selectedYear]?.indexOf(crop) ?? 0;
    return Colors.primaries[index % Colors.primaries.length];
  }
}

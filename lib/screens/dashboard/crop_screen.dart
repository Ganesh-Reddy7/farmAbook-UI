import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crop.dart';
import '../../services/crop_service.dart';
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

class _CropsScreenState extends State<CropsScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isLineChart = false;

  Map<int, List<Crop>> cropsByYear = {};

  @override
  void initState() {
    super.initState();
    _fetchCropsForYear(_selectedYear);
  }

  Future<void> _fetchCropsForYear(int year) async {
    final fetched = await CropService().getCropsByYear(year);
    log("Crops fetched: $fetched");
    setState(() => cropsByYear[year] = fetched);
  }

  Future<void> _refreshCurrentYearCrops() async {
    await _fetchCropsForYear(_selectedYear);
  }

  double safeMaxY(double value) => value > 0 ? value * 1.2 : 1000;

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(
                _isLineChart ? Icons.bar_chart : Icons.show_chart,
                color: widget.accent),
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
              // -------------------- Main Chart --------------------
              SizedBox(
                height: 280,
                child
                    : currentYearCrops.isEmpty
                    ? Center(
                  child: Text(
                    "No Crops data available",
                    style: TextStyle(
                        color: widget.secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                )
                    : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: widget.cardGradientStart.withOpacity(0.05),
                    border: Border.all(color: widget.cardBorder),
                  ),
                  child: _isLineChart
                      ? _buildLineChart(currentYearCrops)
                      : _buildBarChart(currentYearCrops),
                ),
              ),
              const SizedBox(height: 20),

              // -------------------- Year Selector --------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Year:",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.primaryText)),
                  DropdownButton<int>(
                    dropdownColor: Colors.black87,
                    value: _selectedYear,
                    items: List.generate(5, (i) => DateTime.now().year - i)
                        .map((year) => DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: TextStyle(color: widget.primaryText),
                      ),
                    ))
                        .toList(),
                    onChanged: (year) {
                      if (year != null) {
                        setState(() => _selectedYear = year);
                        _fetchCropsForYear(year);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // -------------------- Total Area & Quantity --------------------
              _totalAreaQuantityCard(totalArea, totalQty),
              const SizedBox(height: 20),

              // -------------------- Pie Chart --------------------
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
                    child: Text(
                      "No pie chart data available",
                      style: TextStyle(
                          color: widget.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
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

              // -------------------- Crop List --------------------
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
                    Icon(Icons.info_outline,
                        size: 40, color: widget.accent),
                    const SizedBox(height: 12),
                    Text(
                      "No crops available",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.secondaryText),
                    ),
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

  // -------------------- Bar Chart --------------------
  Widget _buildBarChart(List<Crop> crops) {
    if (crops.isEmpty) return const SizedBox(height: 250);

    double maxY = safeMaxY(
      crops
          .map((c) => [c.totalInvested ?? 0, c.totalReturns ?? 0])
          .expand((e) => e)
          .fold(0.0, (a, b) => a > b ? a : b),
    );

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        groupsSpace: 12,
        barGroups: List.generate(crops.length, (index) {
          final crop = crops[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: crop.totalInvested ?? 0,
                width: 12,
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: crop.totalReturns ?? 0,
                width: 12,
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            barsSpace: 6,
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= crops.length) return const SizedBox();
                return Text(
                  crops[index].name,
                  style: TextStyle(color: widget.primaryText, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                "₹${value.toInt()}",
                style: TextStyle(color: widget.primaryText, fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // -------------------- Line Chart --------------------
  Widget _buildLineChart(List<Crop> crops) {
    if (crops.isEmpty) return const SizedBox(height: 250);

    double maxY = safeMaxY(
      crops
          .map((c) => [c.totalInvested ?? 0, c.totalReturns ?? 0])
          .expand((e) => e)
          .fold(0.0, (a, b) => a > b ? a : b),
    );

    final investedSpots = crops
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value.totalInvested ?? 0)))
        .toList();

    final returnsSpots = crops
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value.totalReturns ?? 0)))
        .toList();

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: investedSpots,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
          LineChartBarData(
            spots: returnsSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= crops.length) return const SizedBox();
                return Text(
                  crops[index].name,
                  style: TextStyle(color: widget.primaryText, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                "₹${value.toInt()}",
                style: TextStyle(color: widget.primaryText, fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
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

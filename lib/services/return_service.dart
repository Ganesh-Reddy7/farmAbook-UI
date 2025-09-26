import '../models/return_model.dart';

class ReturnService {
  // Sample data
  final List<ReturnModel> _sampleReturns = [
    ReturnModel(year: 2019, description: "Wheat Sale", date: DateTime(2019, 3, 5), amount: 4000),
    ReturnModel(year: 2020, description: "Rice Sale", date: DateTime(2020, 6, 12), amount: 6500),
    ReturnModel(year: 2021, description: "Vegetables Sale", date: DateTime(2021, 9, 18), amount: 5000),
    ReturnModel(year: 2022, description: "Fruits Sale", date: DateTime(2022, 11, 23), amount: 7000),
    ReturnModel(year: 2023, description: "Oilseeds Sale", date: DateTime(2023, 2, 10), amount: 9000),
  ];

  // Returns a summary of total returns per year
  Future<List<YearlyReturnSummary>> getYearlySummary({
    required int startYear,
    required int endYear,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    List<YearlyReturnSummary> summary = [];
    for (int y = startYear; y <= endYear; y++) {
      final total = _sampleReturns
          .where((r) => r.year == y)
          .fold<double>(0, (sum, r) => sum + r.amount);
      summary.add(YearlyReturnSummary(year: y, totalAmount: total));
    }
    return summary;
  }

  // Returns list of returns for a specific year
  Future<List<ReturnModel>> getReturnsByYear({required int year}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sampleReturns.where((r) => r.year == year).toList();
  }
}

// Model for yearly summary
class YearlyReturnSummary {
  final int year;
  final double totalAmount;

  YearlyReturnSummary({required this.year, required this.totalAmount});
}
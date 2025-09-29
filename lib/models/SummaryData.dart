class SummaryData {
  final int year;
  final double totalInvestment;
  final double totalRemaining;
  final double totalReturns;
  final double totalProduction;

  SummaryData({
    required this.year,
    required this.totalInvestment,
    required this.totalRemaining,
    required this.totalReturns,
    required this.totalProduction,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      year: json['year'] ?? 0,
      totalInvestment: (json['totalInvestment'] ?? 0).toDouble(),
      totalRemaining: (json['totalRemaining'] ?? 0).toDouble(),
      totalReturns: (json['totalReturns'] ?? 0).toDouble(),
      totalProduction: (json['totalProduction'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'totalInvestment': totalInvestment,
      'totalRemaining': totalRemaining,
      'totalReturns': totalReturns,
      'totalProduction': totalProduction,
    };
  }
}

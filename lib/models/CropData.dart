class CropData {
  final int cropId;
  final String cropName;
  final double totalInvestment;
  final double totalReturns;
  final double profit;
  final double yieldValue;

  CropData({
    required this.cropId,
    required this.cropName,
    required this.totalInvestment,
    required this.totalReturns,
    required this.profit,
    required this.yieldValue,
  });

  factory CropData.fromJson(Map<String, dynamic> json) {
    return CropData(
      cropId: json['cropId'] ?? 0,
      cropName: json['cropName'] ?? '',
      totalInvestment: (json['totalInvestment'] ?? 0).toDouble(),
      totalReturns: (json['totalReturns'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      yieldValue: (json['yield'] ?? 0).toDouble(),
    );
  }
}

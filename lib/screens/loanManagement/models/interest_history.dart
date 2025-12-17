class InterestHistory {
  final int id;
  final String calculationType; // SIMPLE / COMPOUND
  final double principal;
  final double rate;
  final DateTime startDate;
  final DateTime endDate;
  final int timeInMonths;
  final int compoundingFrequency;
  final double interestAmount;
  final double totalAmount;
  final DateTime calculationDate;
  final int farmerId;

  InterestHistory({
    required this.id,
    required this.calculationType,
    required this.principal,
    required this.rate,
    required this.startDate,
    required this.endDate,
    required this.timeInMonths,
    required this.compoundingFrequency,
    required this.interestAmount,
    required this.totalAmount,
    required this.calculationDate,
    required this.farmerId,
  });

  factory InterestHistory.fromJson(Map<String, dynamic> json) {
    return InterestHistory(
      id: json['id'] ?? 0,
      calculationType: json['calculationType'] ?? '',
      principal: (json['principal'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      timeInMonths: json['timeInMonths'] ?? 0,
      compoundingFrequency: json['compoundingFrequency'] ?? 0,
      interestAmount: (json['interestAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      calculationDate: DateTime.parse(json['calculationDate']),
      farmerId: json['farmerId'] ?? 0,
    );
  }
}

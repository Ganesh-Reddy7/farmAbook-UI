class YearlyInvestmentSummaryDTO {
  final int year;
  final double totalAmount;

  YearlyInvestmentSummaryDTO({required this.year, required this.totalAmount});

  factory YearlyInvestmentSummaryDTO.fromJson(Map<String, dynamic> json) {
    return YearlyInvestmentSummaryDTO(
      year: json['year'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

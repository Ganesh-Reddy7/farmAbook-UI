class InterestResult {
  final double interest;
  final double totalAmount;
  final String type;

  InterestResult({
    required this.interest,
    required this.totalAmount,
    required this.type,
  });

  factory InterestResult.fromJson(Map<String, dynamic> json) {
    return InterestResult(
      interest: (json['interest'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      type: json['type'] ?? '',
    );
  }
}

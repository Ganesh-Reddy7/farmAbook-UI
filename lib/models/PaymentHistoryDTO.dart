class PaymentHistoryDTO {
  final int id;
  final double amount;
  final double principalPaid;
  final double interestPaid;
  final String paymentDate;
  final int loanId;

  PaymentHistoryDTO({
    required this.id,
    required this.amount,
    required this.principalPaid,
    required this.interestPaid,
    required this.paymentDate,
    required this.loanId,
  });

  factory PaymentHistoryDTO.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryDTO(
      id: json["id"] ?? 0,
      amount: (json["amount"] ?? 0).toDouble(),
      principalPaid: (json["principalPaid"] ?? 0).toDouble(),
      interestPaid: (json["interestPaid"] ?? 0).toDouble(),
      paymentDate: json["paymentDate"] ?? "",
      loanId: json["loanId"] ?? 0,
    );
  }
}

class LentLoanDTO {
  final int? id;
  final int? farmerId;
  final String? source;
  final double? principal;
  final double? remainingPrincipal;
  final double? amountPaid;
  final double? interestRate;
  final String? startDate;
  final String? endDate;
  final double? finalInterest;
  final bool? isClosed;
  final bool? isGiven;
  final String? description;
  final String? bondImagePath;
  final double? updatedPrincipal;
  final double? currentInterest;
  final String? bondImageFile;
  final int? maturityPeriodYears;
  final String? nextMaturityDate;
  final bool? nearMaturity;
  final String? lastCompoundedDate;

  LentLoanDTO({
    this.id,
    this.farmerId,
    this.source,
    this.principal,
    this.remainingPrincipal,
    this.amountPaid,
    this.interestRate,
    this.startDate,
    this.endDate,
    this.finalInterest,
    this.isClosed,
    this.isGiven,
    this.description,
    this.bondImagePath,
    this.updatedPrincipal,
    this.currentInterest,
    this.bondImageFile,
    this.maturityPeriodYears,
    this.nextMaturityDate,
    this.nearMaturity,
    this.lastCompoundedDate,
  });

  factory LentLoanDTO.fromJson(Map<String, dynamic> json) {
    return LentLoanDTO(
      id: json['id'],
      farmerId: json['farmerId'],
      source: json['source'],
      principal: (json['principal'] != null) ? (json['principal'] as num).toDouble() : null,
      remainingPrincipal: (json['remainingPrincipal'] != null) ? (json['remainingPrincipal'] as num).toDouble() : null,
      amountPaid: (json['amountPaid'] != null) ? (json['amountPaid'] as num).toDouble() : null,
      interestRate: (json['interestRate'] != null) ? (json['interestRate'] as num).toDouble() : null,
      startDate: json['startDate'],
      endDate: json['endDate'],
      finalInterest: (json['finalInterest'] != null) ? (json['finalInterest'] as num).toDouble() : null,
      isClosed: json['isClosed'],
      isGiven: json['isGiven'],
      description: json['description'],
      bondImagePath: json['bondImagePath'],
      updatedPrincipal: (json['updatedPrincipal'] != null) ? (json['updatedPrincipal'] as num).toDouble() : null,
      currentInterest: (json['currentInterest'] != null) ? (json['currentInterest'] as num).toDouble() : null,
      bondImageFile: json['bondImageFile'],
      maturityPeriodYears: json['maturityPeriodYears'],
      nextMaturityDate: json['nextMaturityDate'],
      nearMaturity: json['nearMaturity'],
      lastCompoundedDate: json['lastCompoundedDate'],
    );
  }
}

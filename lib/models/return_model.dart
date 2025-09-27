class ReturnModel {
  final int year;
  final String description;
  final DateTime date;
  final int amount;
  final int quantity;

  ReturnModel({
    required this.year,
    required this.description,
    required this.date,
    required this.amount,
    required this.quantity,
  });

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    return ReturnModel(
      year: (json['year'] as num?)?.toInt() ?? 0,
      description: json['description'] ?? "",
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'description': description,
      'date': date.toIso8601String(),
      'amount': amount,
      'quantity': quantity,
    };
  }
}

class ReturnsList {
  final int cropId;
  final String cropName;
  final double totalReturns;
  final double totalProduction;

  ReturnsList({
    required this.cropId,
    required this.cropName,
    required this.totalReturns,
    required this.totalProduction,
  });

  factory ReturnsList.fromJson(Map<String, dynamic> json) {
    return ReturnsList(
      cropId: json['cropId'] ?? 0,
      cropName: json['cropName'] ?? '',
      totalReturns: (json['totalReturns'] ?? 0).toDouble(),
      totalProduction: (json['totalProduction'] ?? 0).toDouble(),
    );
  }
}

class ReturnDetailModel {
  final int cropId;
  final String cropName;
  final String description;
  final DateTime date;
  final double amount;
  final double quantity;

  ReturnDetailModel({
    required this.cropId,
    required this.cropName,
    required this.description,
    required this.date,
    required this.amount,
    required this.quantity,
  });

  factory ReturnDetailModel.fromJson(Map<String, dynamic> json) {
    return ReturnDetailModel(
      cropId: json['cropId'] ?? 0,
      cropName: json['cropName'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      amount: (json['amount'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toDouble(),
    );
  }
}



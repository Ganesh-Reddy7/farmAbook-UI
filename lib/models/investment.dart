class Investment {
  final int id;
  final DateTime date;
  final String description;
  final double amount;
  final double? remainingAmount;
  final int farmerId;
  final List<Worker>? workers;


  Investment({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.remainingAmount,
    this.workers,
    required this.farmerId,

  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as int,
      date: DateTime.parse(json['date']),
      description: json['description'] ?? "",
      amount: (json['amount'] as num).toDouble(),
      remainingAmount: json['remainingAmount'] != null ? (json['remainingAmount'] as num).toDouble() : null,
      farmerId: json['farmerId'],
      workers: json['workers'] != null
          ? (json['workers'] as List)
          .map((w) => Worker.fromJson(w))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "date": date.toIso8601String(),
      "description": description,
      "amount": amount,
      "workers": workers?.map((w) => w.toJson()).toList(),
    };
  }
}

class Worker {
  final int id;
  final String name;
  final String role;
  final double wage;
  final int investmentId;
  final bool paymentDone;

  Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.wage,
    required this.investmentId,
    required this.paymentDone,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      wage: (json['wage'] as num).toDouble(),
      investmentId: json['investmentId'],
      paymentDone: json['paymentDone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "wage": wage,
      "role": role,
    };
  }
}

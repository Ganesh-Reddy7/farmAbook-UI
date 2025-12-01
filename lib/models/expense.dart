class Expense {
  final int id;
  final int tractorId;
  final DateTime expenseDate;
  final String type;
  final double litres;
  final double cost;
  final String notes;
  final int farmerId;

  Expense({
    required this.id,
    required this.tractorId,
    required this.expenseDate,
    required this.type,
    required this.litres,
    required this.cost,
    required this.notes,
    required this.farmerId,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      tractorId: json['tractorId'],
      expenseDate: DateTime.parse(json['expenseDate']),
      type: json['type'],
      litres: (json['litres'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      notes: json['notes'] ?? "",
      farmerId: json['farmerId'],
    );
  }
}

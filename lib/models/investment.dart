class Investment {
  final int id;
  final DateTime date;
  final String description;
  final double amount;
  final List<Worker>? workers;

  Investment({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.workers,
  });
}

class Worker {
  final String name;
  final double wage;
  final String role;

  Worker({
    required this.name,
    required this.wage,
    required this.role,
  });
}

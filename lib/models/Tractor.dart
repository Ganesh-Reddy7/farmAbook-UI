class Tractor {
  final String id;
  final String serialNumber;
  final String model;
  final String status;

  Tractor({
    required this.id,
    required this.serialNumber,
    required this.model,
    required this.status,
  });

  String get displayName => "$serialNumber - $model";

  factory Tractor.fromJson(Map<String, dynamic> json) {
    return Tractor(
      id: json["id"].toString(),
      serialNumber: json["serialNumber"] ?? "",
      model: json["model"] ?? "",
      status: json["status"] ?? "",
    );
  }
}

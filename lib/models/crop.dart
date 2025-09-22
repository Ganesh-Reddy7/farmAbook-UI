class Crop {
  final int id;
  final String name;
  final DateTime plantedDate;
  final double area; // in acres or hectares
  final double? value; // optional
  final int farmerId;

  Crop({
    required this.id,
    required this.name,
    required this.plantedDate,
    required this.area,
    this.value,
    required this.farmerId,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'],
      name: json['name'],
      plantedDate: DateTime.parse(json['plantedDate']),
      area: (json['area'] as num).toDouble(),
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      farmerId: json['farmerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "plantedDate": plantedDate.toIso8601String(),
      "area": area,
      "value": value,
      "farmerId": farmerId,
    };
  }
}

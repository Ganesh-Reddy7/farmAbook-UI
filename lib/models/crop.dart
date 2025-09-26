class Crop {
  final int id;
  final String name;
  final DateTime? plantedDate;
  final double area; // in acres or hectares
  final double? value; // optional
  final int? farmerId;
  final double? totalInvested;
  final double? totalReturns;

  Crop({
    required this.id,
    required this.name,
    this.plantedDate,
    required this.area,
    this.value,
    this.farmerId,
    this.totalInvested,
    this.totalReturns
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as int,
      name: json['name'] as String,
      plantedDate: json['date'] != null
          ? DateTime.parse(json['date'])
          : null,
      area: (json['area'] as num).toDouble(),
      value: json['area'] != null ? (json['area'] as num).toDouble() : null,
      farmerId: json['farmerId'] as int?,
      totalInvested:json['totalInvestment'],
      totalReturns:json['totalReturns'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "plantedDate": plantedDate?.toIso8601String(),
      "area": area,
      "value": value,
      "farmerId": farmerId,
    };
  }
}

class cropDTO {
  final String cropName;
  final int cropId;

  cropDTO({required this.cropName, required this.cropId});

  factory cropDTO.fromJson(Map<String, dynamic> json) {
    return cropDTO(
      cropName: json['name'].toString(),
      cropId: (json['id'] as num).toInt(),
    );
  }
}

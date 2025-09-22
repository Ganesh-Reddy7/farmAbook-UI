class User {
  final int id;
  final String username;
  final String phone;
  final String role;
  final int farmerId;

  User({required this.id, required this.username, required this.phone , required this.role , required this.farmerId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      phone: json['phone'],
      role:json['role'],
      farmerId: json['farmerId']
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'phone': phone,
    'role':role,
    'farmerId':farmerId
  };
}

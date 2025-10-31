// models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final String password;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.password,
    required this.createdAt,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      password: map['password'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
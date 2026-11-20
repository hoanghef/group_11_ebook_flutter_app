class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.createdAt,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final DateTime? createdAt;
}

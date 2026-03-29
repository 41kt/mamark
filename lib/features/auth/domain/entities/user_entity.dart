class UserEntity {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role; // 'supplier' or 'customer'
  final String? storeName;
  final String? avatarUrl;

  UserEntity({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.storeName,
    this.avatarUrl,
  });
}

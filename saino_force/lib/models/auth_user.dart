class AuthUser {
  final int id;
  final String username;
  final String email;
  final int roleID;

  AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.roleID,
  });
}

class AuthUser {
  final int id;
  final String username;
  final String email;
  final bool isEmailVerified;

  AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.isEmailVerified,
  });
}

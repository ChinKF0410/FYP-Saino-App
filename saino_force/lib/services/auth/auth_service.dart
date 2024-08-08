import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import 'auth_user.dart';
import 'MSSQLAuthProvider.dart';

class AuthService implements AuthProvider {
  static final AuthService _instance =
      AuthService._internal(MSSQLAuthProvider());
  final AuthProvider provider;

  AuthService._internal(this.provider);

  factory AuthService.mssql() => _instance;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final user = await provider.login(email: email, password: password);
    await _saveUserToPreferences(user);  // Add await here
    return user;
  }

  @override
  Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final user = await provider.register(
        username: username, email: email, password: password);
    await _saveUserToPreferences(user);
    return user;
  }


  @override
  Future<void> logout() async {
    await _clearUserFromPreferences();
    return provider.logout();
  }

  @override
  AuthUser? get currentUser {
    return provider.currentUser;
  }

  Future<AuthUser?> getUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    final username = prefs.getString('username');
    final email = prefs.getString('email');
    final loginTimestamp = prefs.getInt('loginTimestamp');

    if (id != null &&
        username != null &&
        email != null &&
        loginTimestamp != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final sessionDuration = currentTime - loginTimestamp;

      const int sessionExpiryDuration = 24 * 60 * 60 * 1000;

      if (sessionDuration < sessionExpiryDuration) {
        return AuthUser(
          id: id,
          username: username,
          email: email,
        );
      } else {
        await _clearUserFromPreferences();
      }
    }
    return null;
  }

  @override
  Future<void> initialize() async {
    await provider.initialize();
    final user = await getUserFromPreferences();
    if (user != null) {
      await provider.login(
        email: user.email,
        password: '',
      );
    }
  }

  Future<void> _saveUserToPreferences(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('userId', user.id);
    prefs.setString('username', user.username);
    prefs.setString('email', user.email);
    prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _clearUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userId');
    prefs.remove('username');
    prefs.remove('email');
    prefs.remove('loginTimestamp');
  }
}

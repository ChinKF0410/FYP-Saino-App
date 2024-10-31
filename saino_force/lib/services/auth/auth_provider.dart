/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:saino_force/models/auth_user.dart';
abstract class AuthProvider {
  Future<int> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String companyname,
  });

  Future<void> logout();
  AuthUser? get currentUser;
  Future<void> initialize();
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  AppSession({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String userDataKey = 'userData';
  static const String userRoleKey = 'userRole';
  static const String staffRoleKey = 'staffRole';
  static const String staffDataKey = 'staffData';
  static const String _userAccessTokenKey = 'retilda.user.accessToken';
  static const String _staffAccessTokenKey = 'retilda.staff.accessToken';
  static const String _biometricEmailKey = 'retilda.biometric.email';
  static const String _biometricPasswordKey = 'retilda.biometric.password';
  static const String _biometricEnabledKey = 'retilda.biometric.enabled';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveUserSession(Map<String, dynamic> responseData) async {
    final prefs = await SharedPreferences.getInstance();
    final data = responseData['data'] as Map<String, dynamic>?;
    final token = data?['token'] as String?;
    final user = data?['user'] as Map<String, dynamic>?;

    if (token != null && token.isNotEmpty) {
      await _secureStorage.write(key: _userAccessTokenKey, value: token);
    }

    final role = extractRole(user?['roles']);
    if (role != null) {
      await prefs.setString(userRoleKey, role);
    }

    if (user != null) {
      await prefs.setString(
          userDataKey,
          jsonEncode({
            'data': {'user': user}
          }));
    }
  }

  Future<void> saveStaffSession({
    required String token,
    Map<String, dynamic>? staff,
  }) async {
    await _secureStorage.write(key: _staffAccessTokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    if (staff != null) {
      final role = staff['role'] as String?;
      if (role != null && role.isNotEmpty) {
        await prefs.setString(staffRoleKey, role);
      }
      await prefs.setString(staffDataKey, jsonEncode(staff));
    }
  }

  Future<String?> userToken() async {
    final token = await _secureStorage.read(key: _userAccessTokenKey);
    if (token != null && token.isNotEmpty) return token;
    return _migrateUserTokenFromPreferences();
  }

  Future<String?> staffToken() async {
    final token = await _secureStorage.read(key: _staffAccessTokenKey);
    if (token != null && token.isNotEmpty) return token;
    return _migrateStaffTokenFromPreferences();
  }

  Future<String?> privilegedToken() async {
    final staff = await staffToken();
    if (staff != null && staff.isNotEmpty) return staff;

    final role = await userRole();
    if (role == 'admin' || role == 'staff') {
      return userToken();
    }
    return null;
  }

  Future<Map<String, dynamic>?> userData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(userDataKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final token = await userToken();
    if (token == null) return decoded;
    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    return {
      ...decoded,
      'data': {
        ...data,
        'token': token,
      },
    };
  }

  Future<String?> userRole() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(userRoleKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final user = await userData();
    final role = extractRole(user?['data']?['user']?['roles']);
    if (role != null) {
      await prefs.setString(userRoleKey, role);
    }
    return role;
  }

  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _userAccessTokenKey);
    await prefs.remove(userDataKey);
    await prefs.remove(userRoleKey);
    await clearBiometricLogin();
  }

  Future<void> clearStaffSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _staffAccessTokenKey);
    await prefs.remove(staffDataKey);
    await prefs.remove(staffRoleKey);
    await prefs.remove('staffToken');
  }

  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _biometricEmailKey, value: email);
    await _secureStorage.write(key: _biometricPasswordKey, value: password);
  }

  Future<Map<String, String>?> biometricCredentials() async {
    final email = await _secureStorage.read(key: _biometricEmailKey);
    final password = await _secureStorage.read(key: _biometricPasswordKey);
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return {
      'email': email,
      'password': password,
    };
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    if (!enabled) {
      await _secureStorage.delete(key: _biometricEmailKey);
      await _secureStorage.delete(key: _biometricPasswordKey);
    }
  }

  Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> clearBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEnabledKey);
    await _secureStorage.delete(key: _biometricEmailKey);
    await _secureStorage.delete(key: _biometricPasswordKey);
  }

  Future<String?> _migrateUserTokenFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(userDataKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final token = decoded['data']?['token'] as String?;
      if (token == null || token.isEmpty) return null;
      await _secureStorage.write(key: _userAccessTokenKey, value: token);
      final data = decoded['data'] as Map<String, dynamic>?;
      final user = data?['user'];
      if (user != null) {
        await prefs.setString(
            userDataKey,
            jsonEncode({
              'data': {'user': user}
            }));
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _migrateStaffTokenFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('staffToken');
    if (token == null || token.isEmpty) return null;
    await _secureStorage.write(key: _staffAccessTokenKey, value: token);
    await prefs.remove('staffToken');
    return token;
  }

  static String? extractRole(dynamic rawRoles) {
    if (rawRoles == null) return null;
    if (rawRoles is String) {
      final role = rawRoles.trim().toLowerCase();
      return role.isEmpty ? null : role;
    }
    if (rawRoles is List) {
      final roles = rawRoles
          .whereType<String>()
          .map((role) => role.trim().toLowerCase())
          .where((role) => role.isNotEmpty)
          .toList();
      if (roles.contains('admin')) return 'admin';
      if (roles.contains('staff')) return 'staff';
      if (roles.contains('user')) return 'user';
      return roles.isNotEmpty ? roles.first : null;
    }
    return null;
  }
}

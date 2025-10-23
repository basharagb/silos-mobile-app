import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'username';
  static const String _roleKey = 'role';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Save login information to SharedPreferences
  Future<void> saveLoginInfo({
    required String token,
    required String username,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.setString(_tokenKey, token),
      prefs.setString(_usernameKey, username),
      prefs.setString(_roleKey, role),
      prefs.setBool(_isLoggedInKey, true),
    ]);
  }

  /// Get stored auth token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Get stored user role
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get all stored login info
  Future<Map<String, String?>> getLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'token': prefs.getString(_tokenKey),
      'username': prefs.getString(_usernameKey),
      'role': prefs.getString(_roleKey),
    };
  }

  /// Clear all stored login information
  Future<void> clearLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_usernameKey),
      prefs.remove(_roleKey),
      prefs.setBool(_isLoggedInKey, false),
    ]);
  }

  /// Check if stored token is valid (mock implementation)
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    
    // In real implementation, you would validate token with backend
    // For now, we'll assume token is valid if it exists
    return true;
  }

  /// Generate a mock token for demo purposes
  String generateMockToken(String username) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'token_${username}_$timestamp';
  }
}

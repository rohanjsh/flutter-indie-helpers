import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A utility class to simplify secure storage operations in Flutter apps.
/// 
/// This helper provides methods to securely store and retrieve various data types,
/// including strings, booleans, integers, doubles, and JSON objects.
class SecureStorageHelper {
  /// The underlying secure storage instance
  final FlutterSecureStorage _storage;
  
  /// Singleton instance
  static final SecureStorageHelper _instance = SecureStorageHelper._internal();
  
  /// Get the singleton instance
  static SecureStorageHelper get instance => _instance;
  
  /// Private constructor
  SecureStorageHelper._internal()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );
  
  /// Save a string value
  Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  /// Read a string value
  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }
  
  /// Save a boolean value
  Future<void> saveBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }
  
  /// Read a boolean value
  Future<bool?> getBool(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }
  
  /// Save an integer value
  Future<void> saveInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }
  
  /// Read an integer value
  Future<int?> getInt(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return int.tryParse(value);
  }
  
  /// Save a double value
  Future<void> saveDouble(String key, double value) async {
    await _storage.write(key: key, value: value.toString());
  }
  
  /// Read a double value
  Future<double?> getDouble(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return double.tryParse(value);
  }
  
  /// Save a JSON object
  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    await _storage.write(key: key, value: jsonString);
  }
  
  /// Read a JSON object
  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await _storage.read(key: key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JSON for key $key: $e');
      return null;
    }
  }
  
  /// Save a list of strings
  Future<void> saveStringList(String key, List<String> list) async {
    final jsonString = jsonEncode(list);
    await _storage.write(key: key, value: jsonString);
  }
  
  /// Read a list of strings
  Future<List<String>?> getStringList(String key) async {
    final jsonString = await _storage.read(key: key);
    if (jsonString == null) return null;
    try {
      final list = jsonDecode(jsonString) as List;
      return list.map((item) => item.toString()).toList();
    } catch (e) {
      print('Error decoding string list for key $key: $e');
      return null;
    }
  }
  
  /// Save user credentials
  Future<void> saveUserCredentials({
    required String userId,
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
  }) async {
    final credentials = {
      'userId': userId,
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (expiresIn != null) 'expiresAt': DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch,
    };
    
    await saveJson('user_credentials', credentials);
  }
  
  /// Get user credentials
  Future<UserCredentials?> getUserCredentials() async {
    final json = await getJson('user_credentials');
    if (json == null) return null;
    
    return UserCredentials(
      userId: json['userId'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int) : null,
    );
  }
  
  /// Check if the access token is expired
  Future<bool> isAccessTokenExpired() async {
    final credentials = await getUserCredentials();
    if (credentials == null || credentials.expiresAt == null) return true;
    
    // Consider token expired 5 minutes before actual expiration
    final expirationWithBuffer = credentials.expiresAt!.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(expirationWithBuffer);
  }
  
  /// Clear user credentials
  Future<void> clearUserCredentials() async {
    await _storage.delete(key: 'user_credentials');
  }
  
  /// Delete a value
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
  
  /// Delete all values
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
  
  /// Get all keys
  Future<Set<String>> getAllKeys() async {
    final all = await _storage.readAll();
    return all.keys.toSet();
  }
}

/// Class to represent user credentials
class UserCredentials {
  final String userId;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  
  UserCredentials({
    required this.userId,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });
  
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Example usage:
///
/// ```dart
/// // Save user credentials
/// await SecureStorageHelper.instance.saveUserCredentials(
///   userId: 'user123',
///   accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
///   refreshToken: 'refresh_token_here',
///   expiresIn: 3600, // 1 hour
/// );
///
/// // Get user credentials
/// final credentials = await SecureStorageHelper.instance.getUserCredentials();
/// if (credentials != null) {
///   print('User ID: ${credentials.userId}');
///   print('Access Token: ${credentials.accessToken}');
///   print('Is Expired: ${credentials.isExpired}');
/// }
///
/// // Save and retrieve other data types
/// await SecureStorageHelper.instance.saveString('username', 'john_doe');
/// await SecureStorageHelper.instance.saveBool('is_premium', true);
/// await SecureStorageHelper.instance.saveInt('login_count', 5);
///
/// final username = await SecureStorageHelper.instance.getString('username');
/// final isPremium = await SecureStorageHelper.instance.getBool('is_premium');
/// final loginCount = await SecureStorageHelper.instance.getInt('login_count');
/// ```

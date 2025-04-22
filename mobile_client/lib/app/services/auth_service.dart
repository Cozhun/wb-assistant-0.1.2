import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_client/app/services/api_service.dart';
import 'package:mobile_client/app/services/storage_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  
  final ApiService _apiService;
  final StorageService _storageService;
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal() 
    : _apiService = ApiService(),
      _storageService = StorageService();
  
  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.client.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final userData = data['user'];
        
        await _saveUserData(token, userData);
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка входа: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    try {
      // Опционально: уведомить сервер о выходе
      await _apiService.client.post('/auth/logout');
    } catch (e) {
      print('Ошибка при выходе на сервере: $e');
    } finally {
      // Удалить локальные данные пользователя
      await _clearUserData();
    }
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }
  
  Future<void> _saveUserData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
  }
  
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
  
  // Вспомогательные методы для работы с API, которые требуют аутентификации
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }
} 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Сервис для локального хранения данных
class StorageService {
  static const String _authBoxName = 'authBox';
  static const String _configBoxName = 'configBox';
  static const String _ordersBoxName = 'ordersBox';
  
  static const String _tokenKey = 'authToken';
  static const String _userKey = 'userData';
  static const String _apiUrlKey = 'apiUrl';
  
  late Box _authBox;
  late Box _configBox;
  late Box _ordersBox;
  late SharedPreferences _prefs;
  
  /// Инициализация хранилища
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Открытие боксов Hive
    _authBox = await Hive.openBox(_authBoxName);
    _configBox = await Hive.openBox(_configBoxName);
    _ordersBox = await Hive.openBox(_ordersBoxName);
  }
  
  /// Сохранение токена авторизации
  Future<void> saveToken(String token) async {
    await _authBox.put(_tokenKey, token);
    await _prefs.setString(_tokenKey, token);
  }
  
  /// Получение токена авторизации
  String? getToken() {
    return _authBox.get(_tokenKey) as String?;
  }
  
  /// Удаление токена авторизации (при выходе из системы)
  Future<void> clearToken() async {
    await _authBox.delete(_tokenKey);
    await _prefs.remove(_tokenKey);
  }
  
  /// Сохранение данных пользователя
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _authBox.put(_userKey, userData);
  }
  
  /// Получение данных пользователя
  Map<String, dynamic>? getUserData() {
    return _authBox.get(_userKey) as Map<String, dynamic>?;
  }
  
  /// Сохранение URL API
  Future<void> saveApiUrl(String url) async {
    await _configBox.put(_apiUrlKey, url);
  }
  
  /// Получение URL API
  String getApiUrl() {
    return _configBox.get(_apiUrlKey, defaultValue: 'http://192.168.1.100:3000') as String;
  }
  
  /// Сохранение списка заказов
  Future<void> saveOrders(List<dynamic> orders) async {
    await _ordersBox.put('ordersList', orders);
  }
  
  /// Получение списка заказов
  List<dynamic>? getOrders() {
    return _ordersBox.get('ordersList') as List<dynamic>?;
  }
  
  /// Сохранение детальной информации о заказе
  Future<void> saveOrderDetails(String orderId, Map<String, dynamic> details) async {
    await _ordersBox.put('order_$orderId', details);
  }
  
  /// Получение детальной информации о заказе
  Map<String, dynamic>? getOrderDetails(String orderId) {
    return _ordersBox.get('order_$orderId') as Map<String, dynamic>?;
  }
  
  /// Очистка кэша заказов
  Future<void> clearOrdersCache() async {
    await _ordersBox.clear();
  }
  
  /// Проверка авторизации пользователя
  bool isUserLoggedIn() {
    return getToken() != null;
  }
  
  /// Полная очистка хранилища (при выходе из системы)
  Future<void> clearAll() async {
    await _authBox.clear();
    await _ordersBox.clear();
    // Не очищаем _configBox, т.к. там настройки
    
    // Очистка SharedPreferences
    await _prefs.remove(_tokenKey);
  }
} 
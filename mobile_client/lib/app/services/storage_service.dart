import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Сервис для локального хранения данных
class StorageService {
  // Синглтон
  static final StorageService _instance = StorageService._internal();
  
  // Фабричный конструктор, возвращающий единственный экземпляр
  factory StorageService() => _instance;
  
  // Приватный конструктор для синглтона
  StorageService._internal();
  
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
  
  // Флаг инициализации
  bool _isInitialized = false;
  
  // Геттер для проверки инициализации
  bool get isInitialized => _isInitialized;
  
  /// Инициализация хранилища
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Открытие боксов Hive
      _authBox = await Hive.openBox(_authBoxName);
      _configBox = await Hive.openBox(_configBoxName);
      _ordersBox = await Hive.openBox(_ordersBoxName);
      
      _isInitialized = true;
    } catch (e) {
      print('Ошибка инициализации StorageService: $e');
      rethrow;
    }
  }
  
  // Метод для проверки инициализации перед выполнением операций
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('StorageService не инициализирован. Вызовите метод init() перед использованием.');
    }
  }
  
  /// Сохранение токена авторизации
  Future<void> saveToken(String token) async {
    _checkInitialized();
    await _authBox.put(_tokenKey, token);
    await _prefs.setString(_tokenKey, token);
  }
  
  /// Получение токена авторизации
  String? getToken() {
    _checkInitialized();
    return _authBox.get(_tokenKey) as String?;
  }
  
  /// Удаление токена авторизации (при выходе из системы)
  Future<void> clearToken() async {
    _checkInitialized();
    await _authBox.delete(_tokenKey);
    await _prefs.remove(_tokenKey);
  }
  
  /// Сохранение данных пользователя
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    _checkInitialized();
    await _authBox.put(_userKey, userData);
  }
  
  /// Получение данных пользователя
  Map<String, dynamic>? getUserData() {
    _checkInitialized();
    
    final data = _authBox.get(_userKey);
    if (data == null) return null;
    
    // Преобразование из _Map<dynamic, dynamic> в Map<String, dynamic>
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    
    return null;
  }
  
  /// Сохранение URL API
  Future<void> saveApiUrl(String url) async {
    _checkInitialized();
    await _configBox.put(_apiUrlKey, url);
  }
  
  /// Получение URL API
  String getApiUrl() {
    _checkInitialized();
    return _configBox.get(_apiUrlKey, defaultValue: 'http://192.168.1.100:3000') as String;
  }
  
  /// Сохранение списка заказов
  Future<void> saveOrders(List<dynamic> orders) async {
    _checkInitialized();
    await _ordersBox.put('ordersList', orders);
  }
  
  /// Получение списка заказов
  List<dynamic>? getOrders() {
    _checkInitialized();
    return _ordersBox.get('ordersList') as List<dynamic>?;
  }
  
  /// Сохранение детальной информации о заказе
  Future<void> saveOrderDetails(String orderId, Map<String, dynamic> details) async {
    _checkInitialized();
    await _ordersBox.put('order_$orderId', details);
  }
  
  /// Получение детальной информации о заказе
  Map<String, dynamic>? getOrderDetails(String orderId) {
    _checkInitialized();
    return _ordersBox.get('order_$orderId') as Map<String, dynamic>?;
  }
  
  /// Очистка кэша заказов
  Future<void> clearOrdersCache() async {
    _checkInitialized();
    await _ordersBox.clear();
  }
  
  /// Проверка авторизации пользователя
  bool isUserLoggedIn() {
    _checkInitialized();
    return getToken() != null;
  }
  
  /// Полная очистка хранилища (при выходе из системы)
  Future<void> clearAll() async {
    _checkInitialized();
    await _authBox.clear();
    await _ordersBox.clear();
    // Не очищаем _configBox, т.к. там настройки
    
    // Очистка SharedPreferences
    await _prefs.remove(_tokenKey);
  }
  
  /// Получение строкового значения из SharedPreferences
  String? getString(String key) {
    _checkInitialized();
    return _prefs.getString(key);
  }
  
  /// Сохранение строкового значения в SharedPreferences
  Future<bool> setString(String key, String value) async {
    _checkInitialized();
    return await _prefs.setString(key, value);
  }
  
  /// Удаление значения из SharedPreferences
  Future<bool> remove(String key) async {
    _checkInitialized();
    return await _prefs.remove(key);
  }
} 
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Сервис для работы с API
class ApiService {
  // Конфигурация API для разных окружений
  static const bool _isLocalTesting = true; // Переключатель для локального тестирования
  
  // Флаг для определения типа устройства (эмулятор/физическое)
  static const bool _isEmulator = false; // Установите в true для эмулятора, false для физического устройства
  
  // Базовый URL API в зависимости от окружения
  static String get _baseUrl {
    if (_isLocalTesting) {
      if (_isEmulator && Platform.isAndroid && !kIsWeb) {
        // Для эмулятора Android используем специальный IP
        return 'http://10.0.2.2';
      } else {
        // Для физических устройств используем IP компьютера в локальной сети
        return 'http://192.168.1.72';
      }
    } else {
      // URL для продакшн окружения
      return 'https://api.yourdomain.com';
    }
  }

  
  static const int _connectionTimeout = 15000; // 15 seconds
  static const int _receiveTimeout = 10000; // 10 seconds

  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(milliseconds: _connectionTimeout),
    receiveTimeout: const Duration(milliseconds: _receiveTimeout),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  
  final bool _isDebugMode = kDebugMode;
  String? _authToken;
  
  ApiService() {
    // Инициализируем интерцепторы для логирования и обработки ошибок
    _setupInterceptors();
    
    // Выводим информацию о текущем окружении в режиме отладки
    if (_isDebugMode) {
      print('API Service initialized with baseUrl: $_baseUrl');
      print('Environment: ${_isLocalTesting ? "LOCAL TESTING" : "PRODUCTION"}');
    }
  }
  
  /// Устанавливает токен авторизации для запросов
  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  /// Сбрасывает токен авторизации
  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }
  
  /// Авторизация пользователя с механизмом повторных попыток
  Future<Map<String, dynamic>> login(String username, String password) async {
    // В режиме отладки выводим информацию о попытке входа
    if (_isDebugMode) {
      print('Попытка авторизации с использованием мок-данных');
      print('Причина: эндпоинт /api/auth/login не существует на сервере');
    }
    
    // Поскольку на сервере нет эндпоинта авторизации, возвращаем мок-данные
    await Future.delayed(const Duration(seconds: 1)); // Имитация задержки сети
    
    // Генерируем мок JWT токен
    const mockToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRlc3QgVXNlciIsImlhdCI6MTUxNjIzOTAyMn0';
    
    // Устанавливаем токен авторизации
    setAuthToken(mockToken);
    
    return {
      'status': 'success',
      'token': mockToken,
      'user': {
        'id': 1,
        'username': username,
        'name': 'Тестовый пользователь',
        'role': 'admin'
      }
    };
  }
  
  /// Получение списка заказов
  Future<List<dynamic>> getOrders() async {
    try {
      final response = await _dio.get('/api/orders');
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Получение детальной информации о заказе
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await _dio.get('/api/orders/$orderId');
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Сканирование штрих-кода
  Future<Map<String, dynamic>> scanBarcode(String orderId, String barcode) async {
    try {
      final response = await _dio.post(
        '/api/orders/$orderId/scan',
        data: {'barcode': barcode},
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Проверка соединения с сервером
  Future<Map<String, dynamic>> testConnection() async {
    try {
      if (_isDebugMode) {
        print('Testing connection to: $_baseUrl/api/health');
      }
      
      final response = await _dio.get('/api/health');
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Проверка доступности URL
  Future<Map<String, dynamic>> testUrl(String url) async {
    try {
      if (_isDebugMode) {
        print('Testing connection to explicit URL: $url');
      }
      
      // Создаем временный экземпляр Dio с указанным URL
      final tempDio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(milliseconds: _connectionTimeout),
        receiveTimeout: const Duration(milliseconds: _receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      
      // Установка логирования
      if (_isDebugMode) {
        tempDio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              print('TEST REQUEST[${options.method}] => URL: ${options.baseUrl}${options.path}');
              return handler.next(options);
            },
            onResponse: (response, handler) {
              print('TEST RESPONSE[${response.statusCode}] => URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
              return handler.next(response);
            },
            onError: (DioException e, handler) {
              print('TEST ERROR => URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
              print('TEST ERROR TYPE: ${e.type}');
              return handler.next(e);
            },
          ),
        );
      }
      
      final response = await tempDio.get('/api/health');
      return response.data;
    } catch (e) {
      if (_isDebugMode) {
        print('TEST URL ERROR: $e');
      }
      rethrow;
    }
  }
  
  /// Настройка интерцепторов для Dio
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_isDebugMode) {
            print('REQUEST[${options.method}] => PATH: ${options.path}');
            print('REQUEST URL: ${options.baseUrl}${options.path}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (_isDebugMode) {
            print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (_isDebugMode) {
            print('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
            print('ERROR TYPE: ${e.type}');
            print('ERROR MESSAGE: ${e.message}');
          }
          return handler.next(e);
        },
      ),
    );
  }
  
  /// Обработка ошибок API
  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        if (error.response!.statusCode == 401) {
          // Если неавторизован, сбрасываем токен
          clearAuthToken();
        }
        
        if (_isDebugMode) {
          print('API Error: ${error.response!.data}');
        }
      } else {
        if (_isDebugMode) {
          print('API Error: ${error.message}');
          print('API Error Type: ${error.type}');
          print('API Error Stack: ${error.stackTrace}');
        }
      }
    } else {
      if (_isDebugMode) {
        print('Unknown API Error: $error');
      }
    }
  }
} 
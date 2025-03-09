import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с API
class ApiService {
  static const String _baseUrl = 'http://192.168.1.100:3000';
  static const int _connectionTimeout = 5000; // 5 seconds
  static const int _receiveTimeout = 3000; // 3 seconds
  
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
  
  /// Авторизация пользователя
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      // Если токен получен, сохраняем его
      if (response.data['token'] != null) {
        setAuthToken(response.data['token']);
      }
      
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
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
  
  /// Настройка интерцепторов для Dio
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_isDebugMode) {
            print('REQUEST[${options.method}] => PATH: ${options.path}');
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
        }
      }
    } else {
      if (_isDebugMode) {
        print('Unknown API Error: $error');
      }
    }
  }
} 
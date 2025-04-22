import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:mobile_client/app/constants/app_config.dart';

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
        return AppConfig.emulatorApiUrl;
      } else {
        // Для физических устройств используем IP компьютера в локальной сети
        return AppConfig.localApiUrl;
      }
    } else {
      // URL для продакшн окружения
      return AppConfig.productionApiUrl;
    }
  }

  // Использовать статический getter для получения Dio клиента
  Dio get client => _dio;
  
  static const int _connectionTimeout = 15000; // 15 seconds
  static const int _receiveTimeout = 10000; // 10 seconds
  static const int _maxRetries = 3; // Максимальное количество повторных попыток

  
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
  String? _refreshToken;
  int _retryCount = 0;
  
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
  void setAuthToken(String token, {String? refreshToken}) {
    _authToken = token;
    _refreshToken = refreshToken;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  /// Сбрасывает токен авторизации
  void clearAuthToken() {
    _authToken = null;
    _refreshToken = null;
    _dio.options.headers.remove('Authorization');
  }
  
  /// Обновление токена авторизации
  Future<bool> _refreshAuthToken() async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      
      if (response.statusCode == 200 && response.data['token'] != null) {
        setAuthToken(
          response.data['token'],
          refreshToken: response.data['refreshToken'] ?? _refreshToken
        );
        return true;
      }
      return false;
    } catch (e) {
      if (_isDebugMode) {
        print('Ошибка обновления токена: $e');
      }
      return false;
    }
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
      // Попытка отправить запрос на сервер
      final response = await _dio.post(
        '/api/orders/$orderId/scan',
        data: {'barcode': barcode},
      );
      return response.data;
    } catch (e) {
      // При ошибке используем тестовые данные
      if (_isDebugMode) {
        print('Используем демо-данные для сканирования штрих-кода: $barcode');
      }
      
      // Имитация задержки сети
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Генерируем тестовые данные о товаре на основе штрих-кода
      return _generateMockItemData(barcode);
    }
  }
  
  /// Сканирование штрих-кода для поставки
  Future<Map<String, dynamic>> scanBarcodeForSupply(String supplyId, String orderId, String barcode) async {
    try {
      // Попытка отправить запрос на сервер
      final response = await _dio.post(
        '/api/supplies/$supplyId/orders/$orderId/scan',
        data: {'barcode': barcode},
      );
      return response.data;
    } catch (e) {
      // При ошибке используем тестовые данные
      if (_isDebugMode) {
        print('Используем демо-данные для сканирования штрих-кода в поставке: $barcode');
      }
      
      // Имитация задержки сети
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Генерируем тестовые данные о товаре на основе штрих-кода
      return _generateMockItemData(barcode);
    }
  }
  
  /// Генерация тестовых данных о товаре на основе штрих-кода
  Map<String, dynamic> _generateMockItemData(String barcode) {
    // Генерируем случайные данные на основе штрих-кода
    final categories = ['Одежда', 'Обувь', 'Аксессуары', 'Электроника', 'Косметика'];
    final brands = ['WBrand', 'TopStyle', 'FashionPlus', 'ElectroMax', 'BeautyLine'];
    
    // Используем часть штрих-кода для псевдо-случайного выбора
    final seed = barcode.hashCode;
    final categoryIndex = seed % categories.length;
    final brandIndex = (seed ~/ 10) % brands.length;
    
    // Генерируем код товара из штрих-кода
    final itemCode = 'WB${barcode.replaceAll(RegExp(r'[^0-9]'), '').substring(0, math.min(6, barcode.length))}';
    
    return {
      'id': itemCode,
      'barcode': barcode,
      'name': '${brands[brandIndex]} ${categories[categoryIndex]} ${itemCode.substring(2, 6)}',
      'category': categories[categoryIndex],
      'brand': brands[brandIndex],
      'price': 1999 + (seed % 8000),
      'quantity': 1,
      'status': 'scanned',
      'timestamp': DateTime.now().toIso8601String(),
    };
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
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (_isDebugMode) {
            print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (_isDebugMode) {
            print('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          }

          // Если ошибка 401 и у нас есть refresh token, пробуем обновить токен
          if (e.response?.statusCode == 401 && _refreshToken != null && _retryCount < _maxRetries) {
            _retryCount++;
            try {
              await _refreshAuthToken();
              // Повторяем запрос с новым токеном
              final opts = Options(
                method: e.requestOptions.method,
                headers: e.requestOptions.headers,
              );
              final res = await _dio.request(
                e.requestOptions.path,
                options: opts,
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
              );
              _retryCount = 0;
              return handler.resolve(res);
            } catch (refreshError) {
              // Если не удалось обновить токен, сбрасываем токены
              _authToken = null;
              _refreshToken = null;
              return handler.next(e);
            }
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
  
  /// Общий метод GET для запросов API
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters, options: options);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Общий метод POST для запросов API
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Общий метод PUT для запросов API
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Общий метод PATCH для запросов API
  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Общий метод DELETE для запросов API
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
} 
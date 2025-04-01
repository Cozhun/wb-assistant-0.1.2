# Интеграция с API

## Обзор

В данном документе описан подход к интеграции Flutter-приложения с существующим API сервера WB Assistant, включая обработку запросов, аутентификацию, обработку ошибок и платформо-специфичные особенности.

## Унифицированный API-клиент

### API-клиент на базе Dio (CL: 90%)

Для взаимодействия с серверным API рекомендуется использовать библиотеку Dio, которая обеспечивает гибкий и мощный HTTP-клиент с поддержкой перехватчиков, трансформаторов, кэширования и других продвинутых функций.

#### Основная структура API-клиента:

```dart
// api/client/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  final Dio _dio;
  
  ApiClient({BaseOptions? options, List<Interceptor>? interceptors}) : 
    _dio = Dio(options ?? _getDefaultOptions()) {
    // Добавление перехватчиков
    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors);
    }
    
    // Добавление стандартных перехватчиков
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => debugPrint(object.toString()),
    ));
  }
  
  static BaseOptions _getDefaultOptions() {
    final baseUrl = kIsWeb 
        ? '/api' // На веб используем относительный путь
        : 'https://api.example.com/api'; // На мобильных полный URL
    
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    );
  }
  
  // Методы для выполнения HTTP-запросов
  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> post(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> put(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> delete(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Обработка ошибок
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      // Обработка ошибок Dio
      return ApiException.fromDioError(error);
    }
    // Общая обработка ошибок
    return ApiException(
      message: error.toString(),
      statusCode: 0,
    );
  }
}

// Класс для унифицированной обработки ошибок API
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;
  
  ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });
  
  factory ApiException.fromDioError(DioException error) {
    int statusCode = error.response?.statusCode ?? 0;
    String message;
    dynamic data = error.response?.data;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Время ожидания соединения истекло';
        break;
      case DioExceptionType.badResponse:
        message = _getMessageFromStatusCode(statusCode);
        break;
      case DioExceptionType.cancel:
        message = 'Запрос был отменен';
        break;
      case DioExceptionType.connectionError:
        message = 'Ошибка соединения с сервером';
        break;
      default:
        message = 'Произошла неизвестная ошибка';
    }
    
    // Если в ответе есть сообщение об ошибке, используем его
    if (data != null && data is Map && data['error'] != null) {
      message = data['error'];
    }
    
    return ApiException(
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }
  
  static String _getMessageFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Неверный запрос';
      case 401:
        return 'Требуется авторизация';
      case 403:
        return 'Доступ запрещен';
      case 404:
        return 'Ресурс не найден';
      case 500:
        return 'Внутренняя ошибка сервера';
      default:
        return 'Ошибка HTTP: $statusCode';
    }
  }
  
  @override
  String toString() => message;
}
```

**Обоснование**: Dio является мощной и гибкой HTTP-библиотекой для Dart, которая обеспечивает широкие возможности для работы с REST API. Унифицированный API-клиент позволяет централизовать обработку запросов, ошибок и аутентификацию.

**Источники**:
- [Dio на pub.dev](https://pub.dev/packages/dio)
- [Making API Calls in Flutter using Dio](https://medium.com/flutter-community/making-api-calls-in-flutter-using-dio-package-74c75a02d8f5)

### Обработка платформенных особенностей (CL: 85%)

#### Перехватчик для платформенно-зависимой логики:

```dart
// api/interceptors/platform_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Добавление заголовков в зависимости от платформы
    if (kIsWeb) {
      // Веб-специфичные заголовки
      options.headers['X-Client-Platform'] = 'web';
      
      // В веб-версии нужно добавить CSRF-токен
      if (options.method != 'GET') {
        options.headers['X-CSRF-Token'] = getCsrfToken();
      }
    } else {
      // Мобильные заголовки
      options.headers['X-Client-Platform'] = 'mobile';
      options.headers['X-App-Version'] = getAppVersion();
      options.headers['X-Device-Id'] = getDeviceId();
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Платформо-специфичная обработка ошибок
    if (kIsWeb) {
      // CORS ошибки специфичны для веб
      if (err.type == DioExceptionType.badResponse && 
          err.response?.statusCode == 0) {
        // Вероятно CORS ошибка
        logCorsError(err);
      }
      
      // Обработка аутентификации в веб
      if (err.response?.statusCode == 401) {
        redirectToLogin();
      }
    } else {
      // Обработка сетевых ошибок на мобильных устройствах
      if (err.type == DioExceptionType.connectionError) {
        checkConnectivity();
      }
    }
    
    handler.next(err);
  }
  
  // Вспомогательные методы для платформо-зависимой логики
  String getCsrfToken() {
    // Реализация получения CSRF-токена для веб
    return '';
  }
  
  String getAppVersion() {
    // Реализация получения версии приложения
    return '1.0.0';
  }
  
  String getDeviceId() {
    // Реализация получения ID устройства
    return '';
  }
  
  void logCorsError(DioException err) {
    // Логирование CORS ошибок
  }
  
  void redirectToLogin() {
    // Перенаправление на страницу входа
  }
  
  Future<void> checkConnectivity() async {
    // Проверка соединения на мобильных устройствах
  }
}
```

**Обоснование**: Перехватчики Dio позволяют элегантно обрабатывать платформенные особенности без загромождения основного кода API-клиента. Это обеспечивает лучшую модульность и тестируемость.

## Аутентификация и авторизация

### JWT-аутентификация (CL: 90%)

Для аутентификации рекомендуется использовать JWT-токены с безопасным хранением в зависимости от платформы.

#### Интерцептор для аутентификации:

```dart
// api/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import '../auth/auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  
  AuthInterceptor(this._authService);
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Получение токена из хранилища
    final token = await _authService.getAuthToken();
    
    if (token != null) {
      // Добавление токена в заголовок
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Если получили 401, возможно токен истек
    if (err.response?.statusCode == 401) {
      // Очистка токена и перенаправление на вход
      _handleUnauthorized();
    }
    
    handler.next(err);
  }
  
  Future<void> _handleUnauthorized() async {
    await _authService.logout();
    // Перенаправление на экран входа
  }
}
```

#### Сервис аутентификации с платформо-зависимой реализацией:

```dart
// api/auth/auth_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}

class WebTokenStorage implements TokenStorage {
  static const String _tokenKey = 'auth_token';
  
  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  @override
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

class MobileTokenStorage implements TokenStorage {
  static const String _tokenKey = 'auth_token';
  final _storage = const FlutterSecureStorage();
  
  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }
  
  @override
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

class AuthService {
  late final TokenStorage _tokenStorage;
  
  AuthService() {
    _tokenStorage = kIsWeb ? WebTokenStorage() : MobileTokenStorage();
  }
  
  Future<String?> getAuthToken() async {
    return _tokenStorage.getToken();
  }
  
  Future<void> saveAuthToken(String token) async {
    await _tokenStorage.saveToken(token);
  }
  
  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }
  
  // Аутентификация пользователя
  Future<bool> login(String username, String password) async {
    try {
      // Реализация логики входа
      // ...
      
      // В случае успеха сохраняем токен
      await saveAuthToken('полученный_токен');
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

**Обоснование**: Использование JWT-токенов с платформо-зависимым хранением обеспечивает безопасность аутентификации как на веб, так и на мобильных устройствах. На мобильных устройствах токены хранятся в защищенном хранилище, а на веб - в SharedPreferences.

**Источники**:
- [flutter_secure_storage на pub.dev](https://pub.dev/packages/flutter_secure_storage)
- [JWT Authentication in Flutter](https://medium.com/flutter-community/jwt-authentication-in-flutter-with-dio-and-flutter-secure-storage-1f2049fb0c5b)

## Обработка ошибок и повторные попытки

### Стратегия обработки ошибок (CL: 85%)

Рекомендуется использовать централизованный подход к обработке ошибок с классификацией ошибок по типам и соответствующей реакцией.

#### Перехватчик для повторных попыток:

```dart
// api/interceptors/retry_interceptor.dart
import 'package:dio/dio.dart';
import 'dart:async';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;
  
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    int retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    
    // Повторяем запрос только если это ошибка соединения или сервер недоступен
    bool shouldRetry = retryCount < maxRetries && (
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.connectionError ||
      (err.response?.statusCode != null && 
       err.response!.statusCode! >= 500 && 
       err.response!.statusCode! < 600)
    );
    
    if (shouldRetry) {
      retryCount++;
      
      // Задержка перед повторной попыткой
      await Future.delayed(retryDelay * retryCount);
      
      try {
        // Создание нового запроса с тем же URL и параметрами
        final options = Options(
          method: err.requestOptions.method,
          headers: err.requestOptions.headers,
          contentType: err.requestOptions.contentType,
          responseType: err.requestOptions.responseType,
          extra: {
            ...err.requestOptions.extra,
            'retryCount': retryCount,
          },
        );
        
        final response = await dio.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: options,
        );
        
        // В случае успеха, возвращаем ответ
        handler.resolve(response);
        return;
      } catch (e) {
        // Если новая попытка также завершилась ошибкой, продолжаем цепочку ошибок
      }
    }
    
    // Если не выполнены условия для повторной попытки или превышено максимальное количество попыток
    handler.next(err);
  }
}
```

**Обоснование**: Перехватчик повторных попыток автоматически обрабатывает временные сетевые ошибки и недоступность сервера, повышая надежность приложения. Экспоненциальная задержка между попытками помогает избежать перегрузки сервера.

## Кэширование и оптимизация

### Стратегия кэширования (CL: 80%)

Для улучшения производительности и обеспечения возможности работы офлайн рекомендуется реализовать кэширование ответов API.

#### Перехватчик для кэширования:

```dart
// api/interceptors/cache_interceptor.dart
import 'package:dio/dio.dart';
import 'dart:convert';

import '../cache/cache_manager.dart';

class CacheInterceptor extends Interceptor {
  final CacheManager cacheManager;
  final Duration maxStale;
  
  CacheInterceptor({
    required this.cacheManager,
    this.maxStale = const Duration(days: 1),
  });
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Кэшируем только GET-запросы
    if (options.method != 'GET') {
      return handler.next(options);
    }
    
    // Если запрос явно требует свежие данные, пропускаем кэш
    if (options.extra['forceRefresh'] == true) {
      return handler.next(options);
    }
    
    // Создаем ключ для кэша на основе URL и параметров
    final cacheKey = _generateCacheKey(options);
    
    try {
      // Получаем данные из кэша
      final cachedResponse = await cacheManager.get(cacheKey);
      
      if (cachedResponse != null) {
        final Map<String, dynamic> responseData = json.decode(cachedResponse);
        
        // Проверяем срок действия кэша
        final DateTime cacheTime = DateTime.parse(responseData['cacheTime']);
        final bool isExpired = DateTime.now().difference(cacheTime) > maxStale;
        
        if (!isExpired) {
          // Возвращаем кэшированный ответ
          final Response response = Response(
            data: responseData['data'],
            statusCode: responseData['statusCode'],
            requestOptions: options,
          );
          
          // Добавляем заголовок, указывающий, что ответ из кэша
          response.headers.add('x-cache', 'HIT');
          
          return handler.resolve(response);
        }
      }
    } catch (e) {
      // В случае ошибки при получении кэша, продолжаем с запросом
    }
    
    // Если нет кэша или он истек, делаем обычный запрос
    return handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Кэшируем только GET-запросы
    if (response.requestOptions.method != 'GET') {
      return handler.next(response);
    }
    
    // Кэшируем только успешные ответы
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final cacheKey = _generateCacheKey(response.requestOptions);
      
      // Сохраняем ответ в кэше
      _saveResponseToCache(cacheKey, response);
    }
    
    handler.next(response);
  }
  
  String _generateCacheKey(RequestOptions options) {
    return '${options.method}_${options.uri}_${json.encode(options.queryParameters)}';
  }
  
  Future<void> _saveResponseToCache(String key, Response response) async {
    final Map<String, dynamic> cacheData = {
      'data': response.data,
      'statusCode': response.statusCode,
      'cacheTime': DateTime.now().toIso8601String(),
    };
    
    await cacheManager.set(key, json.encode(cacheData));
  }
}
```

**Обоснование**: Кэширование ответов API улучшает пользовательский опыт, снижает нагрузку на сервер и обеспечивает базовую работу приложения в режиме офлайн. Стратегия кэширования только GET-запросов соответствует принципам REST.

**Источники**:
- [dio_http_cache на pub.dev](https://pub.dev/packages/dio_http_cache)
- [Implementing API Cache in Flutter](https://medium.com/flutter-community/implementing-api-cache-in-flutter-apps-a54dc2340d30)

## Тестирование API-интеграции

### Подход к тестированию (CL: 85%)

Для обеспечения надежности интеграции с API рекомендуется использовать многоуровневое тестирование:

1. **Юнит-тесты для API-клиента** - проверка корректности формирования запросов и обработки ответов
2. **Интеграционные тесты с моками** - тестирование взаимодействия с API с использованием mock-сервера
3. **Тестирование с реальным сервером** - проверка совместимости с реальным API

#### Пример тестов для API-клиента:

```dart
// test/api/api_client_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:my_app/api/client/api_client.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late ApiClient apiClient;
  
  const baseUrl = 'https://api.example.com/api';
  
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));
    dioAdapter = DioAdapter(dio: dio);
    apiClient = ApiClient(options: dio.options, dio: dio);
  });
  
  group('ApiClient', () {
    test('GET request should return correct data', () async {
      const path = '/warehouses';
      final responseData = {
        'data': [
          {'id': '1', 'name': 'Warehouse 1'},
          {'id': '2', 'name': 'Warehouse 2'},
        ]
      };
      
      dioAdapter.onGet(
        path,
        (request) => request.reply(200, responseData),
      );
      
      final response = await apiClient.get(path);
      
      expect(response.statusCode, 200);
      expect(response.data, responseData);
    });
    
    test('POST request should send correct data', () async {
      const path = '/warehouses';
      final requestData = {'name': 'New Warehouse'};
      final responseData = {'id': '3', 'name': 'New Warehouse'};
      
      dioAdapter.onPost(
        path,
        (request) {
          expect(request.data, requestData);
          return request.reply(201, responseData);
        },
        data: requestData,
      );
      
      final response = await apiClient.post(path, data: requestData);
      
      expect(response.statusCode, 201);
      expect(response.data, responseData);
    });
    
    test('Should handle errors correctly', () async {
      const path = '/warehouses/999';
      final errorData = {'error': 'Warehouse not found'};
      
      dioAdapter.onGet(
        path,
        (request) => request.reply(404, errorData),
      );
      
      expect(
        () => apiClient.get(path),
        throwsA(
          isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Ресурс не найден')
        )
      );
    });
  });
}
```

**Обоснование**: Тестирование API-интеграции необходимо для обеспечения надежности приложения и раннего выявления проблем совместимости с API. Использование mock-сервера позволяет тестировать различные сценарии без зависимости от реального сервера.

**Источники**:
- [http_mock_adapter на pub.dev](https://pub.dev/packages/http_mock_adapter)
- [Testing Flutter Apps](https://flutter.dev/docs/testing)

## Заключение

Правильная архитектура API-клиента является ключевым аспектом успешной миграции на Flutter и интеграции с существующим бэкендом. Использование Dio в сочетании с перехватчиками, абстракциями для платформенно-зависимой логики и стратегиями кэширования обеспечивает гибкое, надежное и производительное решение для взаимодействия с API. 
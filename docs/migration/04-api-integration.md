# Интеграция с API

## Унифицированный API-клиент

Для обеспечения единого взаимодействия с серверной частью как на мобильных устройствах, так и в веб-приложении, необходимо разработать универсальный API-клиент.

### Архитектура API-клиента

```dart
// api/client/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  final Dio _dio;
  
  ApiClient({BaseOptions? options}) : 
    _dio = Dio(options ?? _getDefaultOptions());
  
  static BaseOptions _getDefaultOptions() {
    final baseUrl = kIsWeb 
        ? '/api' // На веб относительный путь
        : 'https://api.example.com/api'; // На мобильных полный URL
    
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    );
  }
  
  // Методы для работы с API
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters
  }) async {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }
  
  // Другие HTTP методы...
}
```

### Обработка особенностей платформ

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
    } else {
      // Мобильные заголовки
      options.headers['X-Client-Platform'] = 'mobile';
      // Дополнительные заголовки для мобильных (User-Agent и т.д.)
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Платформо-специфичная обработка ошибок
    if (kIsWeb) {
      // Обработка CORS и других веб-специфичных ошибок
      if (err.response?.statusCode == 401) {
        // Перенаправление на страницу авторизации в браузере
      }
    } else {
      // Мобильная обработка ошибок
    }
    
    handler.next(err);
  }
}
```

## Интеграция с сервисами аутентификации

### Система аутентификации

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
  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  @override
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

class MobileTokenStorage implements TokenStorage {
  final _storage = const FlutterSecureStorage();
  
  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  @override
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
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
}
```

### Интерцептор для аутентификации

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
    RequestInterceptorHandler handler
  ) async {
    final token = await _authService.getAuthToken();
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err, 
    ErrorInterceptorHandler handler
  ) async {
    if (err.response?.statusCode == 401) {
      // Обработка истекшего токена
      await _authService.logout();
      // Можно также добавить навигацию к экрану входа
    }
    
    handler.next(err);
  }
}
```

## Обработка CORS на веб-платформе

Для веб-клиента важно учитывать ограничения Cross-Origin Resource Sharing (CORS). Поскольку сервер и клиент будут работать через Traefik, необходимо убедиться, что сервер правильно настроен для обработки CORS-запросов.

### Настройка CORS на сервере Express

```javascript
// server/src/app.js
import express from 'express';
import cors from 'cors';
// ...

const app = express();

// Настройка CORS
const corsOptions = {
  origin: process.env.CORS_ORIGIN || '*',
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  preflightContinue: false,
  optionsSuccessStatus: 204
};

app.use(cors(corsOptions));
// ...
```

## Обработка файлов и изображений

### Пример загрузки файлов

```dart
// api/services/upload_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class UploadService {
  final Dio _dio;
  
  UploadService(this._dio);
  
  Future<String> uploadImage({
    required dynamic imageFile, // File для мобильных, Uint8List для веб
    required String fileName
  }) async {
    FormData formData;
    
    if (kIsWeb) {
      // Для веб - работаем с Uint8List
      final bytes = imageFile as List<int>;
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType.parse(lookupMimeType(fileName) ?? 'image/jpeg')
      );
      
      formData = FormData.fromMap({
        'file': multipartFile
      });
    } else {
      // Для мобильных - работаем с File
      final file = imageFile as File;
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(lookupMimeType(file.path) ?? 'image/jpeg')
      );
      
      formData = FormData.fromMap({
        'file': multipartFile
      });
    }
    
    final response = await _dio.post(
      '/upload',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      )
    );
    
    if (response.statusCode == 200) {
      return response.data['url'];
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
```

## Репозитории данных

### Абстракция репозитория

```dart
// api/repositories/base_repository.dart
abstract class BaseRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(int id);
  Future<T> create(T entity);
  Future<T> update(T entity);
  Future<bool> delete(int id);
}
```

### Реализация для конкретной сущности

```dart
// api/repositories/product_repository.dart
import '../client/api_client.dart';
import '../../models/product.dart';

class ProductRepository implements BaseRepository<Product> {
  final ApiClient _apiClient;
  
  ProductRepository(this._apiClient);
  
  @override
  Future<List<Product>> getAll() async {
    final response = await _apiClient.get('/products');
    return (response.data as List)
      .map((item) => Product.fromJson(item))
      .toList();
  }
  
  @override
  Future<Product?> getById(int id) async {
    final response = await _apiClient.get('/products/$id');
    return Product.fromJson(response.data);
  }
  
  @override
  Future<Product> create(Product entity) async {
    final response = await _apiClient.post(
      '/products',
      data: entity.toJson()
    );
    return Product.fromJson(response.data);
  }
  
  @override
  Future<Product> update(Product entity) async {
    final response = await _apiClient.put(
      '/products/${entity.id}',
      data: entity.toJson()
    );
    return Product.fromJson(response.data);
  }
  
  @override
  Future<bool> delete(int id) async {
    final response = await _apiClient.delete('/products/$id');
    return response.statusCode == 200;
  }
} 
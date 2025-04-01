import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_client/app/constants/api_endpoints.dart';
import 'package:mobile_client/app/services/auth_service.dart';
import 'package:mobile_client/modules/requests/models/request_model.dart';
import 'package:mobile_client/modules/requests/models/request_status_model.dart';
import 'package:mobile_client/modules/requests/models/request_type_model.dart';

/// Репозиторий для работы с запросами
class RequestRepository {
  final AuthService _authService;
  final http.Client _httpClient;

  RequestRepository({
    required AuthService authService,
    http.Client? httpClient,
  }) : _authService = authService,
       _httpClient = httpClient ?? http.Client();

  /// Получить все запросы
  Future<List<Request>> getRequests({
    int? statusId,
    int? typeId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (statusId != null) queryParams['statusId'] = statusId.toString();
      if (typeId != null) queryParams['typeId'] = typeId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(ApiEndpoints.requests).replace(queryParameters: queryParams);
      
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при получении запросов: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      
      return items
          .map((item) => Request.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw Exception('Ошибка при получении запросов: $error');
    }
  }

  /// Получить запрос по ID
  Future<Request> getRequestById(int requestId) async {
    try {
      final token = await _authService.getToken();
      
      final response = await _httpClient.get(
        Uri.parse('${ApiEndpoints.requests}/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при получении запроса: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      return Request.fromJson(data);
    } catch (error) {
      throw Exception('Ошибка при получении запроса: $error');
    }
  }

  /// Получить все типы запросов
  Future<List<RequestType>> getRequestTypes() async {
    try {
      final token = await _authService.getToken();
      
      final response = await _httpClient.get(
        Uri.parse(ApiEndpoints.requestTypes),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при получении типов запросов: ${response.statusCode}');
      }

      final data = json.decode(response.body) as List<dynamic>;
      
      return data
          .map((item) => RequestType.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw Exception('Ошибка при получении типов запросов: $error');
    }
  }

  /// Получить все статусы запросов
  Future<List<RequestStatus>> getRequestStatuses() async {
    try {
      final token = await _authService.getToken();
      
      final response = await _httpClient.get(
        Uri.parse(ApiEndpoints.requestStatuses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при получении статусов запросов: ${response.statusCode}');
      }

      final data = json.decode(response.body) as List<dynamic>;
      
      return data
          .map((item) => RequestStatus.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw Exception('Ошибка при получении статусов запросов: $error');
    }
  }

  /// Получить комментарии к запросу
  Future<List<RequestComment>> getRequestComments(int requestId) async {
    try {
      final token = await _authService.getToken();
      
      final response = await _httpClient.get(
        Uri.parse('${ApiEndpoints.requests}/$requestId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при получении комментариев: ${response.statusCode}');
      }

      final data = json.decode(response.body) as List<dynamic>;
      
      return data
          .map((item) => RequestComment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw Exception('Ошибка при получении комментариев: $error');
    }
  }

  /// Получить элементы запроса
  Future<List<RequestItem>> getRequestItems(int requestId) async {
    try {
      final token = await _authService.getToken();
      
      final response = await _httpClient.get(
        Uri.parse('${ApiEndpoints.requests}/$requestId/items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при получении элементов запроса: ${response.statusCode}');
      }

      final data = json.decode(response.body) as List<dynamic>;
      
      return data
          .map((item) => RequestItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw Exception('Ошибка при получении элементов запроса: $error');
    }
  }

  /// Добавить комментарий к запросу
  Future<RequestComment> addRequestComment(int requestId, String comment) async {
    try {
      final token = await _authService.getToken();
      
      final response = await _httpClient.post(
        Uri.parse('${ApiEndpoints.requests}/$requestId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'comment': comment,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Ошибка при добавлении комментария: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      return RequestComment.fromJson(data);
    } catch (error) {
      throw Exception('Ошибка при добавлении комментария: $error');
    }
  }

  /// Изменить статус запроса
  Future<Request> updateRequestStatus(int requestId, int statusId) async {
    try {
      final token = await _authService.getToken();
      
      final response = await _httpClient.patch(
        Uri.parse('${ApiEndpoints.requests}/$requestId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'statusId': statusId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при изменении статуса запроса: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      return Request.fromJson(data);
    } catch (error) {
      throw Exception('Ошибка при изменении статуса запроса: $error');
    }
  }

  /// Создать запрос
  Future<Request> createRequest(Map<String, dynamic> requestData) async {
    try {
      final token = await _authService.getToken();
      
      final response = await _httpClient.post(
        Uri.parse(ApiEndpoints.requests),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      if (response.statusCode != 201) {
        throw Exception('Ошибка при создании запроса: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      return Request.fromJson(data);
    } catch (error) {
      throw Exception('Ошибка при создании запроса: $error');
    }
  }
} 
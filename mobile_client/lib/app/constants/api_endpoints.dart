class ApiEndpoints {
  static const String _baseUrl = 'https://api.example.com/api/v1';

  // Аутентификация
  static const String login = '$_baseUrl/auth/login';
  static const String refreshToken = '$_baseUrl/auth/refresh';
  
  // Заказы
  static const String orders = '$_baseUrl/orders';
  
  // Товары
  static const String products = '$_baseUrl/products';
  
  // Склад
  static const String storage = '$_baseUrl/storage';
  
  // Запросы
  static const String requests = '$_baseUrl/requests';
  static const String requestTypes = '$_baseUrl/request-types';
  static const String requestStatuses = '$_baseUrl/request-statuses';
  
  // Пользователи
  static const String users = '$_baseUrl/users';
  static const String profile = '$_baseUrl/users/profile';
} 
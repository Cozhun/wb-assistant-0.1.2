/// Конфигурация приложения с настройками URL для различных сред
class AppConfig {
  /// URL API для эмулятора Android
  static const String emulatorApiUrl = 'http://10.0.2.2:3000';
  
  /// URL API для локальной разработки на физических устройствах
  static const String localApiUrl = 'http://192.168.1.72:3000';
  
  /// URL API для продакшн окружения
  static const String productionApiUrl = 'https://api.wb-assistant.com';
  
  /// Префикс API для запросов
  static const String apiPrefix = '/api';
  
  /// Таймаут соединения в миллисекундах
  static const int connectionTimeout = 15000;
  
  /// Таймаут получения ответа в миллисекундах
  static const int receiveTimeout = 10000;
  
  /// Включить подробное логирование HTTP запросов
  static const bool enableDetailedHttpLogs = true;
} 
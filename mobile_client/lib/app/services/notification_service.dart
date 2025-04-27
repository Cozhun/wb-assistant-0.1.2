import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../routes/app_router.dart';
import 'storage_service.dart';

/// Сервис уведомлений для мобильного приложения
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final StorageService _storageService = StorageService();
  
  /// Ключ для хранения настроек уведомлений
  static const String _notificationSettingsKey = 'notification_settings';
  
  /// Канал для высокоприоритетных уведомлений
  static const AndroidNotificationChannel _highImportanceChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Важные уведомления',
    description: 'Канал для важных уведомлений',
    importance: Importance.high,
  );
  
  /// Инициализация сервиса уведомлений
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Веб не поддерживает некоторые функции уведомлений
      await _initializeWeb();
    } else {
      // Инициализация для мобильных устройств
      await _initializeMobile();
    }
    
    // Обработка полученных уведомлений
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Обработка нажатия на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  /// Инициализация для веб-платформы
  static Future<void> _initializeWeb() async {
    // Запрос разрешения на веб-уведомления
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Получение токена для веб
    String? token = await _messaging.getToken(
      vapidKey: 'YOUR_VAPID_KEY', // В реальном приложении будет заменено на настоящий ключ
    );
    
    if (token != null) {
      await _saveToken(token);
    }
  }
  
  /// Инициализация для мобильных устройств
  static Future<void> _initializeMobile() async {
    // Запрос разрешения на уведомления
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    // Создание канала для Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_highImportanceChannel);
    
    // Инициализация локальных уведомлений
    const AndroidInitializationSettings androidInitialize = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitialize = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleLocalNotificationTap(response.payload);
      },
    );
    
    // Получение токена для мобильных устройств
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
    
    // Слушатель обновления токена
    _messaging.onTokenRefresh.listen(_saveToken);
  }
  
  /// Обработка сообщения в активном приложении
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Показ локального уведомления для мобильных устройств
    if (!kIsWeb) {
      final notification = message.notification;
      if (notification != null) {
        final android = notification.android;
        final NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            _highImportanceChannel.id,
            _highImportanceChannel.name,
            channelDescription: _highImportanceChannel.description,
            icon: android?.smallIcon,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
        
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          notificationDetails,
          payload: jsonEncode(message.data),
        );
      }
    }
    
    // Обработка данных уведомления
    _processNotificationData(message.data);
  }
  
  /// Обработка нажатия на уведомление (Firebase)
  static void _handleNotificationTap(RemoteMessage message) {
    _processNotificationData(message.data);
  }
  
  /// Обработка нажатия на локальное уведомление
  static void _handleLocalNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _processNotificationData(data);
      } catch (e) {
        print('Ошибка обработки payload уведомления: $e');
      }
    }
  }
  
  /// Обработка данных уведомления
  static void _processNotificationData(Map<String, dynamic> data) {
    // Логика навигации в зависимости от типа уведомления
    if (data.containsKey('type')) {
      final type = data['type'] as String;
      
      switch (type) {
        case 'new_supply':
          final supplyId = data['supplyId'] as String?;
          if (supplyId != null) {
            // Навигация к деталям поставки
            AppRouter.navigateTo('/supplies/$supplyId');
          } else {
            // Навигация к списку поставок
            AppRouter.navigateTo('/supplies');
          }
          break;
          
        case 'supply_update':
          final supplyId = data['supplyId'] as String?;
          if (supplyId != null) {
            // Навигация к деталям поставки
            AppRouter.navigateTo('/supplies/$supplyId');
          }
          break;
          
        case 'shift_status':
          // Навигация к экрану смены
          AppRouter.navigateTo('/shift');
          break;
          
        case 'inventory_task':
          final sessionId = data['sessionId'] as String?;
          if (sessionId != null) {
            // Навигация к сессии инвентаризации
            AppRouter.navigateTo('/inventory/$sessionId');
          } else {
            // Навигация к списку сессий инвентаризации
            AppRouter.navigateTo('/inventory');
          }
          break;
          
        case 'new_request':
          final requestId = data['requestId'] as String?;
          if (requestId != null) {
            // Навигация к деталям запроса
            AppRouter.navigateTo('/requests/$requestId');
          } else {
            // Навигация к списку запросов
            AppRouter.navigateTo('/requests');
          }
          break;
          
        default:
          // По умолчанию навигация на главный экран
          AppRouter.navigateTo('/');
          break;
      }
    }
  }
  
  /// Сохранение токена в базу данных
  static Future<void> _saveToken(String token) async {
    // Инициализация хранилища, если еще не инициализировано
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    // Сохранение токена локально
    await _storageService.setString('fcm_token', token);
    
    // В реальном приложении здесь будет отправка токена на сервер
    // для связывания с профилем пользователя
    print('FCM токен сохранен: $token');
  }
  
  /// Получение текущих настроек уведомлений
  static Future<Map<String, bool>> getNotificationSettings() async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    final settingsJson = _storageService.getString(_notificationSettingsKey);
    if (settingsJson == null || settingsJson.isEmpty) {
      // Настройки по умолчанию, если настройки еще не были сохранены
      return {
        'new_supply': true,
        'supply_update': true,
        'urgent_supply': true,
        'deadline_reminder': true,
        'shift_status': true,
        'inventory_task': true,
        'system_updates': true,
      };
    }
    
    try {
      final Map<String, dynamic> settings = jsonDecode(settingsJson);
      return settings.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      print('Ошибка при чтении настроек уведомлений: $e');
      // Возвращаем настройки по умолчанию в случае ошибки
      return {
        'new_supply': true,
        'supply_update': true,
        'urgent_supply': true,
        'deadline_reminder': true,
        'shift_status': true,
        'inventory_task': true,
        'system_updates': true,
      };
    }
  }
  
  /// Сохранение настроек уведомлений
  static Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    final settingsJson = jsonEncode(settings);
    await _storageService.setString(_notificationSettingsKey, settingsJson);
    
    // Обновление подписок на темы на основе настроек
    await _updateTopicSubscriptions(settings);
  }
  
  /// Обновление подписок на темы уведомлений
  static Future<void> _updateTopicSubscriptions(Map<String, bool> settings) async {
    for (final entry in settings.entries) {
      final topic = entry.key;
      final isEnabled = entry.value;
      
      if (isEnabled) {
        await _messaging.subscribeToTopic(topic);
      } else {
        await _messaging.unsubscribeFromTopic(topic);
      }
    }
  }
  
  /// Подписка на конкретную тему уведомлений
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
  
  /// Отписка от конкретной темы уведомлений
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
} 
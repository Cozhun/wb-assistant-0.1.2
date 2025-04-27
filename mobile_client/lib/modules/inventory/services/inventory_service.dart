import 'dart:convert';
import '../models/inventory_session.dart';
import '../models/inventory_item.dart';
import '../../../app/services/api_service.dart';
import '../../../app/services/storage_service.dart';

/// Сервис для работы с инвентаризацией
class InventoryService {
  final ApiService _apiService;
  final StorageService _storageService;
  
  /// Ключ для хранения активного сеанса инвентаризации в локальном хранилище
  static const String _activeSessionKey = 'active_inventory_session';

  /// Конструктор с внедрением зависимостей
  InventoryService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();
  
  /// Получает список сеансов инвентаризации для текущего пользователя
  Future<List<InventorySession>> getSessions() async {
    try {
      final response = await _apiService.get('/inventory/sessions');
      
      final sessions = (response.data as List)
          .map((session) => InventorySession.fromJson(session as Map<String, dynamic>))
          .toList();
      
      return sessions;
    } catch (e) {
      // В случае ошибки сети, пытаемся получить данные из локального хранилища
      return _getLocalSessions();
    }
  }
  
  /// Получает сеанс инвентаризации по ID
  Future<InventorySession> getSessionById(String sessionId) async {
    try {
      final response = await _apiService.get('/inventory/sessions/$sessionId');
      return InventorySession.fromJson(response.data);
    } catch (e) {
      // В случае ошибки сети, пытаемся получить данные из локального хранилища
      final localSessions = await _getLocalSessions();
      final session = localSessions.firstWhere(
        (session) => session.id == sessionId,
        orElse: () => throw Exception('Сеанс инвентаризации не найден'),
      );
      return session;
    }
  }
  
  /// Начинает сеанс инвентаризации
  Future<InventorySession> startSession(String sessionId) async {
    try {
      final response = await _apiService.post('/inventory/sessions/$sessionId/start');
      
      final session = InventorySession.fromJson(response.data);
      
      // Сохраняем активный сеанс в локальное хранилище
      await _saveLocalSession(session);
      
      return session;
    } catch (e) {
      // В случае ошибки сети, пытаемся получить данные из локального хранилища и обновить статус
      final session = await getSessionById(sessionId);
      session.status = InventorySessionStatus.inProgress;
      
      // Сохраняем обновленный сеанс в локальное хранилище
      await _saveLocalSession(session);
      
      return session;
    }
  }
  
  /// Завершает сеанс инвентаризации
  Future<InventorySession> completeSession(String sessionId) async {
    try {
      final response = await _apiService.post('/inventory/sessions/$sessionId/complete');
      
      final session = InventorySession.fromJson(response.data);
      
      // Удаляем активный сеанс из локального хранилища
      await _clearLocalSession();
      
      return session;
    } catch (e) {
      // В случае ошибки сети, пытаемся получить данные из локального хранилища и обновить статус
      final session = await getSessionById(sessionId);
      session.updateStatus();
      
      // Если все элементы проверены, считаем сеанс завершенным
      if (session.items.every((item) => item.isCompleted)) {
        session.status = InventorySessionStatus.completed;
      }
      
      // Сохраняем обновленный сеанс для последующей синхронизации
      await _saveLocalSession(session);
      
      return session;
    }
  }
  
  /// Обновляет элемент инвентаризации
  Future<InventoryItem> updateItem(String sessionId, InventoryItem item) async {
    try {
      final response = await _apiService.put(
        '/inventory/sessions/$sessionId/items/${item.id}',
        data: item.toJson(),
      );
      
      final updatedItem = InventoryItem.fromJson(response.data);
      
      // Обновляем элемент в локальном хранилище
      await _updateLocalSessionItem(sessionId, updatedItem);
      
      return updatedItem;
    } catch (e) {
      // В случае ошибки сети, сохраняем элемент в локальное хранилище для последующей синхронизации
      await _updateLocalSessionItem(sessionId, item);
      
      return item;
    }
  }
  
  /// Получает список сеансов из локального хранилища
  Future<List<InventorySession>> _getLocalSessions() async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    final sessionJson = _storageService.getString(_activeSessionKey);
    if (sessionJson == null || sessionJson.isEmpty) {
      return [];
    }
    
    try {
      final session = InventorySession.fromJson(jsonDecode(sessionJson));
      return [session];
    } catch (e) {
      return [];
    }
  }
  
  /// Сохраняет сеанс в локальное хранилище
  Future<void> _saveLocalSession(InventorySession session) async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    await _storageService.setString(_activeSessionKey, jsonEncode(session.toJson()));
  }
  
  /// Удаляет активный сеанс из локального хранилища
  Future<void> _clearLocalSession() async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    await _storageService.remove(_activeSessionKey);
  }
  
  /// Сканирование товара для инвентаризации
  Future<Map<String, dynamic>> scanItemForInventory(
    String sessionId, 
    String barcode, 
    [String? itemId]
  ) async {
    try {
      // Попытка отправки данных на сервер
      final response = await _apiService.post(
        '/inventory/sessions/$sessionId/scan',
        data: {
          'barcode': barcode,
          if (itemId != null) 'itemId': itemId,
        },
      );
      
      final result = response.data;
      
      // Получаем обновленный сеанс инвентаризации
      final updatedSession = await getSessionById(sessionId);
      
      // Сохраняем в локальное хранилище
      await _saveLocalSession(updatedSession);
      
      return result;
    } catch (e) {
      // В случае ошибки сети, эмулируем сканирование
      // Получаем сеанс из локального хранилища
      final session = await getSessionById(sessionId);
      
      // Если указан конкретный элемент, ищем его
      InventoryItem? targetItem;
      if (itemId != null) {
        targetItem = session.items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => throw Exception('Элемент инвентаризации не найден'),
        );
      } else {
        // Иначе пытаемся найти по штрих-коду
        targetItem = session.items.firstWhere(
          (item) => item.barcode == barcode,
          orElse: () => throw Exception('Товар с штрих-кодом $barcode не найден в этой сессии'),
        );
      }
      
      // Обновляем количество
      final updatedQuantity = (targetItem.actualQuantity ?? 0) + 1;
      
      // Определяем статус элемента
      InventoryStatus newStatus;
      if (updatedQuantity == targetItem.expectedQuantity) {
        newStatus = InventoryStatus.completed;
      } else {
        newStatus = InventoryStatus.discrepancy;
      }
      
      // Создаем новый объект с обновленными данными
      final updatedItem = targetItem.copyWith(
        actualQuantity: updatedQuantity,
        status: newStatus
      );
      
      // Обновляем элемент в локальном хранилище
      await _updateLocalSessionItem(sessionId, updatedItem);
      
      // Возвращаем результат сканирования
      return {
        'id': updatedItem.id,
        'barcode': updatedItem.barcode,
        'name': updatedItem.name,
        'expectedQuantity': updatedItem.expectedQuantity,
        'actualQuantity': updatedItem.actualQuantity,
        'status': updatedItem.status.toString(),
        'sessionId': sessionId,
        'message': 'Товар учтен в инвентаризации',
      };
    }
  }
  
  /// Обновляет элемент в локальном сеансе
  Future<void> _updateLocalSessionItem(String sessionId, InventoryItem item) async {
    final sessions = await _getLocalSessions();
    final sessionIndex = sessions.indexWhere((session) => session.id == sessionId);
    
    if (sessionIndex == -1) {
      return;
    }
    
    final session = sessions[sessionIndex];
    final itemIndex = session.items.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) {
      session.items.add(item);
    } else {
      session.items[itemIndex] = item;
    }
    
    // Обновляем статус сеанса
    session.updateStatus();
    
    // Сохраняем обновленный сеанс
    await _saveLocalSession(session);
  }
} 
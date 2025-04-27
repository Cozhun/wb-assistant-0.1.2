import 'dart:convert';
import '../models/shift_status.dart';
import '../../../app/services/storage_service.dart';
import '../../../app/services/api_service.dart';

/// Сервис для управления сменами
class ShiftService {
  static const String _shiftKey = 'current_shift';
  final StorageService _storageService;
  final ApiService _apiService;

  /// Конструктор с внедрением зависимостей
  ShiftService({
    StorageService? storageService,
    ApiService? apiService,
  })  : _storageService = storageService ?? StorageService(),
        _apiService = apiService ?? ApiService();

  /// Получение текущего статуса смены
  Future<ShiftStatus> getCurrentShift() async {
    // Проверяем, что хранилище инициализировано
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }

    // Получаем данные смены из локального хранилища
    final shiftJson = _storageService.getString(_shiftKey);
    if (shiftJson == null || shiftJson.isEmpty) {
      return ShiftStatus.initial();
    }

    try {
      return ShiftStatus.fromJson(jsonDecode(shiftJson));
    } catch (e) {
      // В случае ошибки возвращаем начальное состояние
      return ShiftStatus.initial();
    }
  }

  /// Начало смены
  Future<ShiftStatus> startShift() async {
    final currentShift = await getCurrentShift();
    
    // Если смена уже активна, возвращаем текущий статус
    if (currentShift.isActive) {
      return currentShift;
    }
    
    // Создаем новую активную смену
    final newShift = ShiftStatus.active();
    
    // Сохраняем на сервере (если онлайн)
    try {
      final response = await _apiService.post('/shifts/start', data: newShift.toJson());
      final shiftFromServer = ShiftStatus.fromJson(response.data);
      
      // Сохраняем в локальном хранилище
      await _saveShiftLocally(shiftFromServer);
      return shiftFromServer;
    } catch (e) {
      // Если не удалось синхронизировать с сервером, сохраняем локально
      await _saveShiftLocally(newShift);
      return newShift;
    }
  }

  /// Завершение смены
  Future<ShiftStatus> endShift() async {
    final currentShift = await getCurrentShift();
    
    // Если смена не активна, возвращаем текущий статус
    if (!currentShift.isActive) {
      return currentShift;
    }
    
    // Создаем завершенную смену
    final completedShift = ShiftStatus.completed(currentShift);
    
    // Сохраняем на сервере (если онлайн)
    try {
      final response = await _apiService.post('/shifts/end', data: completedShift.toJson());
      final shiftFromServer = ShiftStatus.fromJson(response.data);
      
      // Сохраняем в локальном хранилище
      await _saveShiftLocally(shiftFromServer);
      return shiftFromServer;
    } catch (e) {
      // Если не удалось синхронизировать с сервером, сохраняем локально
      await _saveShiftLocally(completedShift);
      return completedShift;
    }
  }

  /// Обновление данных о смене
  Future<ShiftStatus> updateShift(ShiftStatus updatedShift) async {
    // Сохраняем на сервере (если онлайн)
    try {
      final response = await _apiService.put('/shifts/${updatedShift.id}', data: updatedShift.toJson());
      final shiftFromServer = ShiftStatus.fromJson(response.data);
      
      // Сохраняем в локальном хранилище
      await _saveShiftLocally(shiftFromServer);
      return shiftFromServer;
    } catch (e) {
      // Если не удалось синхронизировать с сервером, сохраняем локально
      await _saveShiftLocally(updatedShift);
      return updatedShift;
    }
  }

  /// Увеличение счетчика собранных заказов
  Future<ShiftStatus> incrementCompletedOrders() async {
    final currentShift = await getCurrentShift();
    
    // Если смена не активна, возвращаем текущий статус
    if (!currentShift.isActive) {
      return currentShift;
    }
    
    // Обновляем счетчик
    final updatedShift = currentShift.copyWith(
      completedOrders: currentShift.completedOrders + 1,
    );
    
    return updateShift(updatedShift);
  }

  /// Сохранение смены в локальное хранилище
  Future<void> _saveShiftLocally(ShiftStatus shift) async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    await _storageService.setString(_shiftKey, jsonEncode(shift.toJson()));
  }
} 
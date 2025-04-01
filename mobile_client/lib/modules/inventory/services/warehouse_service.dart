import '../models/warehouse_cell.dart';
import '../../../app/services/api_service.dart';

/// Сервис для работы со складом
class WarehouseService {
  final ApiService _apiService;
  
  /// Конструктор с внедрением зависимостей
  WarehouseService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();
  
  /// Получение ячеек по зоне (секции)
  Future<List<WarehouseCell>> getCellsByZone(String zone) async {
    try {
      // В реальном приложении здесь был бы запрос к API
      final response = await _apiService.get('/warehouse/cells', queryParameters: {
        'zone': zone,
      });
      
      final List<dynamic> data = response.data;
      return data.map((json) => WarehouseCell.fromJson(json)).toList();
    } catch (e) {
      // Для демонстрации возвращаем тестовые данные
      return _getMockCells(zone);
    }
  }
  
  /// Получение всех секций склада
  Future<List<String>> getAllSections() async {
    try {
      final response = await _apiService.get('/warehouse/sections');
      final List<dynamic> data = response.data;
      return data.map((e) => e.toString()).toList();
    } catch (e) {
      // Для демонстрации возвращаем тестовые данные
      return ['A', 'B', 'C', 'D', 'E'];
    }
  }
  
  /// Поиск товара на складе
  Future<List<WarehouseCell>> findItemLocation(String articleId) async {
    try {
      final response = await _apiService.get('/warehouse/items/location', queryParameters: {
        'articleId': articleId,
      });
      
      final List<dynamic> data = response.data;
      return data.map((json) => WarehouseCell.fromJson(json)).toList();
    } catch (e) {
      // Для демонстрации возвращаем тестовые данные
      return _getMockCells('A').where((cell) => 
        cell.articleIds.contains(articleId)).toList();
    }
  }
  
  /// Инициирование инвентаризации ячейки
  Future<void> initiateInventory(String cellId) async {
    try {
      await _apiService.post('/warehouse/inventory/initiate', data: {
        'cellId': cellId,
      });
    } catch (e) {
      // В демонстрационном режиме просто возвращаем успех
      return;
    }
  }
  
  /// Получение тестовых данных для демонстрации
  List<WarehouseCell> _getMockCells(String zone) {
    final cells = <WarehouseCell>[];
    
    for (int i = 1; i <= 9; i++) {
      final FillingLevel level;
      
      // Равномерное распределение уровней заполнения для демонстрации
      if (i % 4 == 0) {
        level = FillingLevel.empty;
      } else if (i % 4 == 1) {
        level = FillingLevel.low;
      } else if (i % 4 == 2) {
        level = FillingLevel.medium;
      } else {
        level = FillingLevel.high;
      }
      
      cells.add(
        WarehouseCell(
          id: '$zone$i',
          section: zone,
          position: '$i',
          fillingLevel: level,
          articleIds: ['WB${10000 + i}', 'WB${20000 + i}'],
        ),
      );
    }
    
    return cells;
  }
} 
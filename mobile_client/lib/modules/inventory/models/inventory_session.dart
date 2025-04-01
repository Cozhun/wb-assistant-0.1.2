import 'inventory_item.dart';

/// Модель сеанса инвентаризации
class InventorySession {
  /// Идентификатор сеанса инвентаризации
  final String id;
  
  /// Название сеанса инвентаризации
  final String name;
  
  /// Дата создания сеанса
  final DateTime createdAt;
  
  /// Статус сеанса инвентаризации
  InventorySessionStatus status;
  
  /// Зона инвентаризации (например, A1-A8)
  final String zone;
  
  /// Список элементов инвентаризации
  List<InventoryItem> items;
  
  /// Исполнитель инвентаризации
  final String assignedToUserId;
  
  /// Имя исполнителя инвентаризации
  final String assignedToUserName;
  
  /// Создает сеанс инвентаризации
  InventorySession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.status,
    required this.zone,
    required this.items,
    required this.assignedToUserId,
    required this.assignedToUserName,
  });
  
  /// Прогресс инвентаризации (процент завершенных элементов)
  double get progress {
    if (items.isEmpty) return 0.0;
    final completedCount = items.where((item) => item.isCompleted).length;
    return completedCount / items.length;
  }
  
  /// Количество завершенных элементов
  int get completedCount {
    return items.where((item) => item.isCompleted).length;
  }
  
  /// Количество элементов с расхождениями
  int get discrepancyCount {
    return items.where((item) => item.hasDiscrepancy).length;
  }
  
  /// Проверяет, завершен ли сеанс инвентаризации
  bool get isCompleted {
    return status == InventorySessionStatus.completed;
  }
  
  /// Обновляет статус сеанса на основе состояния элементов
  void updateStatus() {
    if (items.every((item) => item.isCompleted)) {
      status = InventorySessionStatus.completed;
    } else if (items.any((item) => item.status != InventoryStatus.pending)) {
      status = InventorySessionStatus.inProgress;
    } else {
      status = InventorySessionStatus.pending;
    }
  }
  
  /// Создает сеанс инвентаризации из JSON
  factory InventorySession.fromJson(Map<String, dynamic> json) {
    return InventorySession(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: InventorySessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InventorySessionStatus.pending,
      ),
      zone: json['zone'] as String,
      items: (json['items'] as List)
          .map((item) => InventoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      assignedToUserId: json['assignedToUserId'] as String,
      assignedToUserName: json['assignedToUserName'] as String,
    );
  }
  
  /// Преобразует сеанс инвентаризации в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'zone': zone,
      'items': items.map((item) => item.toJson()).toList(),
      'assignedToUserId': assignedToUserId,
      'assignedToUserName': assignedToUserName,
    };
  }
}

/// Статус сеанса инвентаризации
enum InventorySessionStatus {
  /// Ожидает начала
  pending,
  
  /// В процессе инвентаризации
  inProgress,
  
  /// Инвентаризация завершена
  completed,
  
  /// Выявлены расхождения, требуется проверка
  needsReview,
} 
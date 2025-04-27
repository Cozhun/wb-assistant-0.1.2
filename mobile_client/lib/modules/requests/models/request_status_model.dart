/// Модель статуса запроса
class RequestStatus {
  final int statusId;
  final String name;
  final String? description;
  final String? color;
  final bool isActive;
  final bool isFinal;
  final int sortOrder;

  RequestStatus({
    required this.statusId,
    required this.name,
    this.description,
    this.color,
    required this.isActive,
    required this.isFinal,
    required this.sortOrder,
  });

  /// Создание из JSON
  factory RequestStatus.fromJson(Map<String, dynamic> json) {
    return RequestStatus(
      statusId: json['statusId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      isActive: json['isActive'] as bool,
      isFinal: json['isFinal'] as bool,
      sortOrder: json['sortOrder'] as int,
    );
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'statusId': statusId,
      'name': name,
      'description': description,
      'color': color,
      'isActive': isActive,
      'isFinal': isFinal,
      'sortOrder': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RequestStatus &&
        other.statusId == statusId &&
        other.name == name;
  }

  @override
  int get hashCode => statusId.hashCode ^ name.hashCode;
} 
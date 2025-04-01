/// Модель типа запроса
class RequestType {
  final int requestTypeId;
  final String name;
  final String? description;
  final String? color;
  final bool isActive;

  RequestType({
    required this.requestTypeId,
    required this.name,
    this.description,
    this.color,
    required this.isActive,
  });

  /// Создание из JSON
  factory RequestType.fromJson(Map<String, dynamic> json) {
    return RequestType(
      requestTypeId: json['requestTypeId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      isActive: json['isActive'] as bool,
    );
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'requestTypeId': requestTypeId,
      'name': name,
      'description': description,
      'color': color,
      'isActive': isActive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RequestType &&
        other.requestTypeId == requestTypeId &&
        other.name == name;
  }

  @override
  int get hashCode => requestTypeId.hashCode ^ name.hashCode;
} 
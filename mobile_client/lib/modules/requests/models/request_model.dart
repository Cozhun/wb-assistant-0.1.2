
/// Модель запроса
class Request {
  final int requestId;
  final int enterpriseId;
  final int requestTypeId;
  final String requestNumber;
  final String title;
  final String? description;
  final int statusId;
  final int createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final RequestPriority priority;
  final DateTime? estimatedCompletionDate;
  final int? assignedTo;

  // Дополнительные данные
  final String? typeName;
  final String? statusName;
  final String? statusColor;

  Request({
    required this.requestId,
    required this.enterpriseId,
    required this.requestTypeId,
    required this.requestNumber,
    required this.title,
    this.description,
    required this.statusId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    required this.priority,
    this.estimatedCompletionDate,
    this.assignedTo,
    this.typeName,
    this.statusName,
    this.statusColor,
  });

  /// Создание из JSON
  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      requestId: json['requestId'] as int,
      enterpriseId: json['enterpriseId'] as int,
      requestTypeId: json['requestTypeId'] as int,
      requestNumber: json['requestNumber'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      statusId: json['statusId'] as int,
      createdBy: json['createdBy'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      priority: _getPriorityFromString(json['priority'] as String),
      estimatedCompletionDate: json['estimatedCompletionDate'] != null
          ? DateTime.parse(json['estimatedCompletionDate'] as String)
          : null,
      assignedTo: json['assignedTo'] as int?,
      typeName: json['typeName'] as String?,
      statusName: json['statusName'] as String?,
      statusColor: json['statusColor'] as String?,
    );
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'enterpriseId': enterpriseId,
      'requestTypeId': requestTypeId,
      'requestNumber': requestNumber,
      'title': title,
      'description': description,
      'statusId': statusId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority.toString().split('.').last,
      'estimatedCompletionDate': estimatedCompletionDate?.toIso8601String(),
      'assignedTo': assignedTo,
    };
  }

  /// Конвертация из строки в RequestPriority
  static RequestPriority _getPriorityFromString(String priorityStr) {
    switch (priorityStr) {
      case 'URGENT':
        return RequestPriority.urgent;
      case 'HIGH':
        return RequestPriority.high;
      case 'NORMAL':
        return RequestPriority.normal;
      case 'LOW':
        return RequestPriority.low;
      default:
        return RequestPriority.normal;
    }
  }

  /// Копирование с изменением некоторых полей
  Request copyWith({
    int? requestId,
    int? enterpriseId,
    int? requestTypeId,
    String? requestNumber,
    String? title,
    String? description,
    int? statusId,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    RequestPriority? priority,
    DateTime? estimatedCompletionDate,
    int? assignedTo,
    String? typeName,
    String? statusName,
    String? statusColor,
  }) {
    return Request(
      requestId: requestId ?? this.requestId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      requestTypeId: requestTypeId ?? this.requestTypeId,
      requestNumber: requestNumber ?? this.requestNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      statusId: statusId ?? this.statusId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      estimatedCompletionDate: estimatedCompletionDate ?? this.estimatedCompletionDate,
      assignedTo: assignedTo ?? this.assignedTo,
      typeName: typeName ?? this.typeName,
      statusName: statusName ?? this.statusName,
      statusColor: statusColor ?? this.statusColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Request &&
        other.requestId == requestId &&
        other.requestNumber == requestNumber;
  }

  @override
  int get hashCode => requestId.hashCode ^ requestNumber.hashCode;
}

/// Приоритет запроса
enum RequestPriority {
  urgent,
  high,
  normal,
  low
}

/// Элемент запроса
class RequestItem {
  final int requestItemId;
  final int requestId;
  final int productId;
  final int quantity;
  final int statusId;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Дополнительные данные
  final String? productName;
  final String? sku;
  final String? productDescription;

  RequestItem({
    required this.requestItemId,
    required this.requestId,
    required this.productId,
    required this.quantity,
    required this.statusId,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.productName,
    this.sku,
    this.productDescription,
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    return RequestItem(
      requestItemId: json['requestItemId'] as int,
      requestId: json['requestId'] as int,
      productId: json['productId'] as int,
      quantity: json['quantity'] as int,
      statusId: json['statusId'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      productName: json['productName'] as String?,
      sku: json['sku'] as String?,
      productDescription: json['productDescription'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestItemId': requestItemId,
      'requestId': requestId,
      'productId': productId,
      'quantity': quantity,
      'statusId': statusId,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Комментарий к запросу
class RequestComment {
  final int commentId;
  final int requestId;
  final int userId;
  final String comment;
  final DateTime createdAt;
  
  // Дополнительные данные
  final String? userName;
  final String? email;

  RequestComment({
    required this.commentId,
    required this.requestId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    this.userName,
    this.email,
  });

  factory RequestComment.fromJson(Map<String, dynamic> json) {
    return RequestComment(
      commentId: json['commentId'] as int,
      requestId: json['requestId'] as int,
      userId: json['userId'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userName: json['userName'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'requestId': requestId,
      'userId': userId,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 
import 'dart:convert';
import '../../../app/services/api_service.dart';
import '../../../app/services/storage_service.dart';
import '../models/order.dart';

/// Сервис для работы с заказами
class OrderService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  /// Получение списка всех заказов
  Future<List<Order>> getOrders() async {
    try {
      final response = await _apiService.getOrders();
      
      // Преобразуем в модели Order и сортируем по дате
      final orders = response
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList();
          
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Сохраняем в кэш
      await _storageService.saveOrders(response);
      
      return orders;
    } catch (e) {
      // Пытаемся загрузить из кэша в случае ошибки
      final cachedOrders = _storageService.getOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        return cachedOrders
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Не удалось загрузить заказы: ${e.toString()}');
    }
  }
  
  /// Получение заказа по ID
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _apiService.get('/orders/$orderId');
      return Order.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Пытаемся найти заказ в кэше
      final cachedOrders = _storageService.getOrders();
      if (cachedOrders != null) {
        final orderData = cachedOrders.firstWhere(
          (o) => (o as Map<String, dynamic>)['id'] == orderId,
          orElse: () => null,
        );
        
        if (orderData != null) {
          return Order.fromJson(orderData as Map<String, dynamic>);
        }
      }
      throw Exception('Не удалось загрузить заказ: ${e.toString()}');
    }
  }
  
  /// Обновление статуса заказа
  Future<Order> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _apiService.put(
        '/orders/$orderId/status',
        data: jsonEncode({'status': status}),
      );
      
      // Обновляем заказ в кэше
      final updatedOrder = Order.fromJson(response as Map<String, dynamic>);
      _updateOrderInCache(updatedOrder);
      
      return updatedOrder;
    } catch (e) {
      throw Exception('Не удалось обновить статус заказа: ${e.toString()}');
    }
  }
  
  /// Обновление позиции заказа (собрано)
  Future<Order> updateOrderItemCollectionStatus(
    String orderId, 
    String itemId, 
    int collectedQuantity,
  ) async {
    try {
      final response = await _apiService.put(
        '/orders/$orderId/items/$itemId',
        data: jsonEncode({'collectedQuantity': collectedQuantity}),
      );
      
      // Обновляем заказ в кэше
      final updatedOrder = Order.fromJson(response as Map<String, dynamic>);
      _updateOrderInCache(updatedOrder);
      
      return updatedOrder;
    } catch (e) {
      throw Exception('Не удалось обновить статус позиции заказа: ${e.toString()}');
    }
  }
  
  /// Пометить заказ как невозможный к сборке
  Future<Order> markOrderAsImpossibleToCollect(
    String orderId, 
    String reason,
  ) async {
    try {
      final response = await _apiService.put(
        '/orders/$orderId/impossible',
        data: jsonEncode({
          'impossibleToCollect': true,
          'impossibilityReason': reason,
          'impossibilityDate': DateTime.now().toIso8601String(),
        }),
      );
      
      // Обновляем заказ в кэше
      final updatedOrder = Order.fromJson(response as Map<String, dynamic>);
      _updateOrderInCache(updatedOrder);
      
      return updatedOrder;
    } catch (e) {
      throw Exception('Не удалось пометить заказ как невозможный к сборке: ${e.toString()}');
    }
  }
  
  /// Списать невозможный к сборке заказ
  Future<Order> fulfillImpossibleOrder(String orderId) async {
    try {
      final response = await _apiService.put(
        '/orders/$orderId/fulfill',
        data: jsonEncode({
          'status': OrderStatus.fulfilled,
          'completedAt': DateTime.now().toIso8601String(),
        }),
      );
      
      // Обновляем заказ в кэше
      final updatedOrder = Order.fromJson(response as Map<String, dynamic>);
      _updateOrderInCache(updatedOrder);
      
      return updatedOrder;
    } catch (e) {
      throw Exception('Не удалось списать невозможный к сборке заказ: ${e.toString()}');
    }
  }
  
  /// Обновление заказа в кэше
  void _updateOrderInCache(Order updatedOrder) {
    final cachedOrders = _storageService.getOrders();
    if (cachedOrders != null) {
      final updatedOrders = cachedOrders.map((o) {
        final order = o as Map<String, dynamic>;
        if (order['id'] == updatedOrder.id) {
          return updatedOrder.toJson();
        }
        return order;
      }).toList();
      
      _storageService.saveOrders(updatedOrders);
    }
  }
} 
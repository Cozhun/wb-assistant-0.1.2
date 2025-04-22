import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../../../app/services/api_service.dart';
import '../../../app/services/storage_service.dart';

/// Контроллер для управления заказами
class OrdersController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final OrderService _orderService = OrderService();
  final StorageService _storageService = StorageService();
  
  // Переменные состояния
  List<Order> orders = [];
  List<Order> wbOrders = [];
  bool isLoading = false;
  String errorMessage = '';
  
  /// Инициализация контроллера
  OrdersController() {
    loadOrders();
  }
  
  /// Загрузка всех заказов
  Future<void> loadOrders() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      // Загрузка обычных заказов
      final regularOrders = await _orderService.getOrders();
      orders = regularOrders;
      
      // Загрузка заказов Wildberries через сервер
      await loadWildberriesOrders();
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Ошибка при загрузке заказов: ${e.toString()}';
      isLoading = false;
      notifyListeners();
    }
  }
  
  /// Загрузка заказов Wildberries с сервера
  Future<void> loadWildberriesOrders() async {
    try {
      // Запрос новых заказов с сервера
      final response = await _apiService.get('/api/wb-api/orders/new');
      
      final List<Order> fetchedWbOrders = (response as List<dynamic>)
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList();
      
      wbOrders = fetchedWbOrders;
    } catch (e) {
      errorMessage += '\nОшибка загрузки заказов Wildberries: ${e.toString()}';
    }
  }
  
  /// Получение заказа по ID
  Future<Order> getOrderById(String orderId) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      final order = await _orderService.getOrderById(orderId);
      
      isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      errorMessage = 'Ошибка при загрузке заказа: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Обновление статуса заказа
  Future<Order> updateOrderStatus(String orderId, String status) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      final updatedOrder = await _orderService.updateOrderStatus(orderId, status);
      
      // Обновляем заказ в списке
      final index = orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        orders[index] = updatedOrder;
      }
      
      isLoading = false;
      notifyListeners();
      return updatedOrder;
    } catch (e) {
      errorMessage = 'Ошибка при обновлении статуса заказа: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Обновление позиции заказа (собрано)
  Future<Order> updateOrderItemCollectionStatus(
    String orderId, 
    String itemId, 
    int collectedQuantity,
  ) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      final updatedOrder = await _orderService.updateOrderItemCollectionStatus(
        orderId, 
        itemId, 
        collectedQuantity,
      );
      
      // Обновляем заказ в списке
      final index = orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        orders[index] = updatedOrder;
      }
      
      isLoading = false;
      notifyListeners();
      return updatedOrder;
    } catch (e) {
      errorMessage = 'Ошибка при обновлении статуса позиции заказа: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Пометить заказ как невозможный к сборке
  Future<Order> markOrderAsImpossibleToCollect(
    String orderId, 
    String reason,
  ) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      final updatedOrder = await _orderService.markOrderAsImpossibleToCollect(
        orderId, 
        reason,
      );
      
      // Обновляем заказ в списке
      final index = orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        orders[index] = updatedOrder;
      }
      
      isLoading = false;
      notifyListeners();
      return updatedOrder;
    } catch (e) {
      errorMessage = 'Ошибка при установке статуса "невозможно собрать": ${e.toString()}';
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Интеграция с API Wildberries через сервер
  
  /// Подтверждение заказа WB
  Future<void> confirmWbOrder(String orderId) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      await _apiService.patch('/api/wb-api/orders/$orderId/confirm');
      
      // Обновляем статус заказа в списке
      final index = wbOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        wbOrders[index] = wbOrders[index].copyWith(status: 'confirmed');
      }
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Ошибка при подтверждении заказа WB: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Отмена заказа WB
  Future<void> cancelWbOrder(String orderId, String reason) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      await _apiService.patch('/api/wb-api/orders/$orderId/cancel', data: {
        'reason': reason
      });
      
      // Обновляем статус заказа в списке
      final index = wbOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        wbOrders[index] = wbOrders[index].copyWith(status: 'cancelled');
      }
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Ошибка при отмене заказа WB: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Получение этикеток для заказов WB
  Future<String?> getWbOrderStickers(List<String> orderIds, String type) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      final response = await _apiService.post('/api/wb-api/orders/stickers', data: {
        'orderIds': orderIds,
        'type': type
      });
      
      isLoading = false;
      notifyListeners();
      return response['data'];
    } catch (e) {
      errorMessage = 'Ошибка при получении этикеток WB: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Получение информации о клиенте WB
  Future<Map<String, dynamic>?> getWbClientInfo(List<String> orderIds) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
      
      final response = await _apiService.post('/api/wb-api/orders/client', data: {
        'orderIds': orderIds
      });
      
      isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      errorMessage = 'Ошибка при получении информации о клиенте WB: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
} 
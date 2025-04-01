import 'dart:convert';
import 'dart:math';
import '../../../app/services/api_service.dart';
import '../../../app/services/storage_service.dart';
import '../models/supply.dart';
import '../models/order.dart';

/// Сервис для управления поставками
class SupplyService {
  final ApiService _apiService;
  final StorageService _storageService;
  static const String _supplyCacheKey = 'cached_supplies';
  
  /// Конструктор с возможностью внедрения зависимостей
  SupplyService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();
        
  /// Получение списка поставок
  Future<List<Supply>> getSupplies({
    bool? filterActive,
    bool? filterToday,
    bool? filterTomorrow,
    bool? filterOverdue,
  }) async {
    try {
      // Подготовка параметров запроса
      final queryParams = <String, dynamic>{};
      if (filterActive != null) queryParams['active'] = filterActive;
      if (filterToday != null) queryParams['today'] = filterToday;
      if (filterTomorrow != null) queryParams['tomorrow'] = filterTomorrow;
      if (filterOverdue != null) queryParams['overdue'] = filterOverdue;
      
      // Отправка запроса на сервер
      final response = await _apiService.get('/api/supplies', queryParameters: queryParams);
      
      // Преобразование ответа в список объектов Supply
      final List<dynamic> suppliesData = response.data;
      final supplies = suppliesData
          .map((data) => Supply.fromJson(data))
          .toList();
      
      // Сохранение в кэш
      _cacheSupplies(supplies);
      
      return supplies;
    } catch (e) {
      // В случае ошибки пытаемся использовать кэшированные данные
      return _getCachedSupplies();
    }
  }
  
  /// Получение детальной информации о поставке
  Future<Supply> getSupplyDetails(String id) async {
    try {
      final response = await _apiService.get('/api/supplies/$id');
      return Supply.fromJson(response.data);
    } catch (e) {
      // Проверяем, есть ли поставка в кэше
      final cachedSupplies = await _getCachedSupplies();
      final cachedSupply = cachedSupplies.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Не удалось загрузить данные о поставке: $e'),
      );
      return cachedSupply;
    }
  }
  
  /// Создание новой поставки
  Future<Supply> createSupply(Supply supply) async {
    final response = await _apiService.post('/api/supplies', data: supply.toJson());
    final createdSupply = Supply.fromJson(response.data);
    
    // Обновляем кэш
    final cachedSupplies = await _getCachedSupplies();
    cachedSupplies.add(createdSupply);
    _cacheSupplies(cachedSupplies);
    
    return createdSupply;
  }
  
  /// Обновление поставки
  Future<Supply> updateSupply(Supply supply) async {
    final response = await _apiService.put('/api/supplies/${supply.id}', data: supply.toJson());
    final updatedSupply = Supply.fromJson(response.data);
    
    // Обновляем кэш
    final cachedSupplies = await _getCachedSupplies();
    final index = cachedSupplies.indexWhere((s) => s.id == supply.id);
    if (index >= 0) {
      cachedSupplies[index] = updatedSupply;
      _cacheSupplies(cachedSupplies);
    }
    
    return updatedSupply;
  }
  
  /// Обновление статуса поставки
  Future<Supply> updateSupplyStatus(String id, SupplyStatus status) async {
    final response = await _apiService.patch(
      '/api/supplies/$id/status',
      data: {'status': status.index},
    );
    final updatedSupply = Supply.fromJson(response.data);
    
    // Обновляем кэш
    final cachedSupplies = await _getCachedSupplies();
    final index = cachedSupplies.indexWhere((s) => s.id == id);
    if (index >= 0) {
      cachedSupplies[index] = updatedSupply;
      _cacheSupplies(cachedSupplies);
    }
    
    return updatedSupply;
  }
  
  /// Назначение сборщика на поставку
  Future<Supply> assignCollector(String id, String collectorName) async {
    final response = await _apiService.patch(
      '/api/supplies/$id/assign',
      data: {'assignedTo': collectorName},
    );
    final updatedSupply = Supply.fromJson(response.data);
    
    // Обновляем кэш
    final cachedSupplies = await _getCachedSupplies();
    final index = cachedSupplies.indexWhere((s) => s.id == id);
    if (index >= 0) {
      cachedSupplies[index] = updatedSupply;
      _cacheSupplies(cachedSupplies);
    }
    
    return updatedSupply;
  }
  
  /// Добавление заказа в поставку
  Future<Supply> addOrderToSupply(String supplyId, String orderId) async {
    final response = await _apiService.post(
      '/api/supplies/$supplyId/orders',
      data: {'orderId': orderId},
    );
    final updatedSupply = Supply.fromJson(response.data);
    
    // Обновляем кэш
    final cachedSupplies = await _getCachedSupplies();
    final index = cachedSupplies.indexWhere((s) => s.id == supplyId);
    if (index >= 0) {
      cachedSupplies[index] = updatedSupply;
      _cacheSupplies(cachedSupplies);
    }
    
    return updatedSupply;
  }
  
  /// Удаление заказа из поставки
  Future<Supply> removeOrderFromSupply(String supplyId, String orderId) async {
    final response = await _apiService.delete(
      '/api/supplies/$supplyId/orders/$orderId',
    );
    final updatedSupply = Supply.fromJson(response.data);
    
    // Обновляем кэш
    final cachedSupplies = await _getCachedSupplies();
    final index = cachedSupplies.indexWhere((s) => s.id == supplyId);
    if (index >= 0) {
      cachedSupplies[index] = updatedSupply;
      _cacheSupplies(cachedSupplies);
    }
    
    return updatedSupply;
  }
  
  /// Получение кэшированных поставок
  Future<List<Supply>> _getCachedSupplies() async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    final cachedData = _storageService.getString(_supplyCacheKey);
    if (cachedData == null || cachedData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> parsedData = jsonDecode(cachedData);
      return parsedData
          .map((data) => Supply.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Сохранение поставок в кэш
  Future<void> _cacheSupplies(List<Supply> supplies) async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    final jsonData = jsonEncode(supplies.map((s) => s.toJson()).toList());
    await _storageService.setString(_supplyCacheKey, jsonData);
  }
  
  /// Получить мок-данные поставок для демонстрации
  Future<List<Supply>> getMockSupplies() async {
    // Имитируем задержку сервера
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Создаем тестовые заказы с разными статусами
    final pendingOrder1 = Order(
      id: '1',
      wbOrderNumber: 'WB-12345',
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      customer: 'Иванов Иван',
      address: 'Москва, ул. Пушкина, д. 10',
      item: _createMockOrderItem('1', 'Смартфон Samsung Galaxy S21', 3),
    );
    
    final inProgressOrder = Order(
      id: '2',
      wbOrderNumber: 'WB-12346',
      status: OrderStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      customer: 'Петрова Анна',
      address: 'Санкт-Петербург, пр. Невский, д. 20',
      item: _createMockOrderItem('2', 'Наушники Sony WH-1000XM4', 2),
    );
    
    final verifiedOrder = Order(
      id: '3',
      wbOrderNumber: 'WB-12347',
      status: OrderStatus.verified,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      customer: 'Сидоров Алексей',
      address: 'Екатеринбург, ул. Ленина, д. 5',
      item: _createFullyVerifiedMockOrderItem('3', 'Ноутбук ASUS Zenbook', 1),
    );
    
    final packedOrder = Order(
      id: '4',
      wbOrderNumber: 'WB-12348',
      status: OrderStatus.packed,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      customer: 'Козлов Дмитрий',
      address: 'Новосибирск, ул. Гагарина, д. 15',
      item: _createFullyPackedMockOrderItem('4', 'Фотоаппарат Canon EOS R6', 2),
      isLabelPrinted: true,
    );
    
    final readyToShipOrder = Order(
      id: '5',
      wbOrderNumber: 'WB-12349',
      status: OrderStatus.readyToShip,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      dueDate: DateTime.now(),
      customer: 'Николаева Елена',
      address: 'Казань, ул. Баумана, д. 12',
      item: _createFullyPackedMockOrderItem('5', 'Планшет iPad Pro', 1),
      isLabelPrinted: true,
      isOrderStickerPrinted: true,
    );
    
    final completedOrder = Order(
      id: '6',
      wbOrderNumber: 'WB-12350',
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      customer: 'Кузнецов Артем',
      address: 'Владивосток, ул. Светланская, д. 7',
      item: _createFullyPackedMockOrderItem('6', 'Умные часы Apple Watch', 1),
      isLabelPrinted: true,
      isOrderStickerPrinted: true,
    );
    
    final pendingOrder2 = Order(
      id: '7',
      wbOrderNumber: 'WB-12351',
          status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: DateTime.now().add(const Duration(days: 4)),
      customer: 'Морозова Ольга',
      address: 'Сочи, ул. Навагинская, д. 9',
      item: _createMockOrderItem('7', 'Кофемашина DeLonghi', 3),
    );
    
    final impossibleOrder = Order(
      id: '8',
      wbOrderNumber: 'WB-12352',
      status: OrderStatus.impossibleToCollect,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      customer: 'Соколов Максим',
      address: 'Краснодар, ул. Красная, д. 18',
      item: _createMockOrderItem('8', 'Игровая приставка PlayStation 5', 2),
      impossibleToCollect: true,
      impossibilityReason: 'Товар отсутствует на складе',
      impossibilityDate: DateTime.now().subtract(const Duration(hours: 12)),
    );
    
    return [
      // Активная поставка в процессе сборки с разными статусами заказов
      Supply(
        id: 'supply-1',
        name: 'Поставка #1 от ${_formatDate(DateTime.now())}',
        description: 'Активная поставка для тестирования',
        status: SupplyStatus.collecting,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        shipmentDate: DateTime.now().add(const Duration(days: 3)),
        assignedTo: 'Иванов И.И.',
        orders: [pendingOrder1, inProgressOrder, verifiedOrder, packedOrder, readyToShipOrder],
        progress: 0.6, // 60% выполнено
        totalOrders: 5,
        completedOrders: 3,
      ),
      
      // Поставка, ожидающая отгрузки (все заказы собраны)
      Supply(
        id: 'supply-2',
        name: 'Поставка #2 от ${_formatDate(DateTime.now().subtract(const Duration(days: 5)))}',
        description: 'Поставка ожидает отгрузки',
        status: SupplyStatus.waitingShipment,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        shipmentDate: DateTime.now().add(const Duration(days: 1)),
        assignedTo: 'Петров П.П.',
        orders: [readyToShipOrder, completedOrder],
        progress: 1.0, // 100% выполнено
        totalOrders: 2,
        completedOrders: 2,
      ),
      
      // Поставка, отгруженная на склад WB
      Supply(
        id: 'supply-3',
        name: 'Поставка #3 от ${_formatDate(DateTime.now().subtract(const Duration(days: 10)))}',
        description: 'Поставка отгружена на склад WB',
        status: SupplyStatus.shipped,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        shipmentDate: DateTime.now().subtract(const Duration(days: 2)),
        assignedTo: 'Сидоров С.С.',
        orders: [completedOrder],
        progress: 1.0, // 100% выполнено
        totalOrders: 1,
        completedOrders: 1,
      ),
      
      // Новая поставка с проблемным заказом
      Supply(
        id: 'supply-4',
        name: 'Поставка #4 от ${_formatDate(DateTime.now())}',
        description: 'Новая поставка с проблемным заказом',
        status: SupplyStatus.collecting,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        shipmentDate: DateTime.now().add(const Duration(days: 5)),
        assignedTo: 'Козлов К.К.',
        orders: [pendingOrder2, impossibleOrder],
        progress: 0.0, // 0% выполнено
        totalOrders: 2,
        completedOrders: 0,
      ),
    ];
  }
  
  /// Создать мок-данные товара заказа
  OrderItem _createMockOrderItem(String id, String name, int productCount) {
    return OrderItem(
      id: id,
      name: name,
      article: 'ART-${10000 + int.parse(id)}',
      barcode: '123456789${id.padLeft(4, '0')}',
      totalPrice: (10000 + Random().nextInt(90000)) / 100,
      products: List.generate(productCount, (index) {
        return ProductItem(
          id: '$id-$index',
          name: '$name (${index + 1})',
          barcode: '123456789${id.padLeft(2, '0')}${index + 1}',
          article: 'ART-${10000 + int.parse(id)}-${index + 1}',
          quantity: 1,
          price: (5000 + Random().nextInt(5000)) / 100,
          imageUrl: 'https://picsum.photos/seed/$id-$index/200/300',
        );
      }),
      imageUrl: 'https://picsum.photos/seed/$id/200/300',
    );
  }
  
  /// Создать мок-данные полностью верифицированного товара заказа
  OrderItem _createFullyVerifiedMockOrderItem(String id, String name, int productCount) {
    return OrderItem(
      id: id,
      name: name,
      article: 'ART-${10000 + int.parse(id)}',
      barcode: '123456789${id.padLeft(4, '0')}',
      totalPrice: (10000 + Random().nextInt(90000)) / 100,
      isVerified: true,
      products: List.generate(productCount, (index) {
        return ProductItem(
          id: '$id-$index',
          name: '$name (${index + 1})',
          barcode: '123456789${id.padLeft(2, '0')}${index + 1}',
          article: 'ART-${10000 + int.parse(id)}-${index + 1}',
          quantity: 1,
          price: (5000 + Random().nextInt(5000)) / 100,
          imageUrl: 'https://picsum.photos/seed/$id-$index/200/300',
          isVerified: true,
        );
      }),
      imageUrl: 'https://picsum.photos/seed/$id/200/300',
    );
  }
  
  /// Создать мок-данные полностью упакованного товара заказа
  OrderItem _createFullyPackedMockOrderItem(String id, String name, int productCount) {
    return OrderItem(
      id: id,
      name: name,
      article: 'ART-${10000 + int.parse(id)}',
      barcode: '123456789${id.padLeft(4, '0')}',
      totalPrice: (10000 + Random().nextInt(90000)) / 100,
      isVerified: true,
      isPacked: true,
      products: List.generate(productCount, (index) {
        return ProductItem(
          id: '$id-$index',
          name: '$name (${index + 1})',
          barcode: '123456789${id.padLeft(2, '0')}${index + 1}',
          article: 'ART-${10000 + int.parse(id)}-${index + 1}',
          quantity: 1,
          price: (5000 + Random().nextInt(5000)) / 100,
          imageUrl: 'https://picsum.photos/seed/$id-$index/200/300',
          isVerified: true,
          isPacked: true,
        );
      }),
      imageUrl: 'https://picsum.photos/seed/$id/200/300',
    );
  }
  
  /// Форматирование даты в строку
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
} 